pragma solidity ^0.6.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Governance{
    
    using SafeMath for uint256;
    
    uint256 proposalCreationFeeUSD = 100; // usd
    uint256 votingFeeUSD = 1; // usd
    uint256 XETHUSDRate = 350; // usd
    
    uint256 public totalProposals;
    uint256 public proposalPeriod = 7 days;
    uint256 public totalEarningsClaimed;
    
    address BREE = 0x8c1eD7e19abAa9f23c476dA86Dc1577F1Ef401f5;
    
    string[] categories;
    mapping(uint256 => Proposal) public proposals;
    
    enum Status {_, ACCEPTED, REJECTED, ACTIVE}
    
    struct Proposal{
        uint256 id;
        string description;
        uint256 categoryId;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes; 
        address creator;
        uint256 yesTrustScores;
        uint256 noTrustScores;
        uint256 totalBreePaid;
        Status status;
    }
    
    struct proposalsVotes{
        bool voted;
        bool choice; // true = yes, false = no
        uint256 breePaid;
    }
    
    struct Voters{
        mapping(uint256 => proposalsVotes) proposalsVoted;
        uint256 gainedTrustScore;
        uint256 deductedTrustScore;
        uint256 trustScoreLastUpdated; // save the index of allProposalsVoted till where we calculated trust score
        uint256[] allProposalsVoted;
    }
    
    // TODO trust score logic
    function trustScore(address user) private returns(uint256 _trustScore){
        for(uint256 i = voters[user].trustScoreLastUpdated; i<= voters[user].allProposalsVoted.length; i++){
            
        }
    }
    
    mapping(address => Voters) voters;
    
    constructor() public {
        // set the mapping
        categories.push("StakingRates");
        categories.push("FarmingRates");
        categories.push("AddDeleteGovernanceAsset");
        categories.push("StakerWhitelisting");
        categories.push("StakingPeriod");
        categories.push("StakingRewardsCollectionFees");
        categories.push("YieldCollectionFees");
        categories.push("ProposalCreationFees");
        categories.push("VotingFees");
        categories.push("VotesDistribution");
        categories.push("TrustScores");
        categories.push("Others");
    }
    
    modifier validCategory(uint256 categoryId){
        require(categoryId >= 0 && categoryId <= categories.length, "CATEGORY ID: Invalid Category Id");
        _;
    }
    
    modifier descriptionNotNull(string memory ideaDescription){
        bytes memory ideaDescriptionBytes = bytes(ideaDescription); // Uses memory
        require(ideaDescriptionBytes.length != 0, "Description NULL: Proposal description should not be null");
        _;
    }
    
    modifier notVoted(uint256 proposalId){
        require(!voters[msg.sender].proposalsVoted[proposalId].voted);
        _;
    }
    
    // Create proposal by paying fee in BREE
    function CREATE_PROPOSAL(uint256 categoryId, string memory ideaDescription) external validCategory(categoryId) descriptionNotNull(ideaDescription){
        // get the fee from user
        IERC20(BREE).transferFrom(msg.sender, address(this), _calculateProposalFee());
        
        // burn the received tokens
        IERC20(BREE).burnTokens(_calculateProposalFee());
        
        // REGISTER THE PROPOSAL
        
        // increment the proposals count
        totalProposals = totalProposals.add(1);
        
        // add the proposal to mapping
        proposals[totalProposals] = Proposal({
           id: totalProposals,
           description: ideaDescription,
           categoryId: categoryId,
           startTime: block.timestamp,
           endTime: block.timestamp.add(proposalPeriod),
           status: Status.ACTIVE,
           creator: msg.sender,
           yesVotes: 0,
           noVotes: 0,
           yesTrustScores: 0,
           noTrustScores: 0,
           totalBreePaid: 0
        });
    }
    
    // TO DO LOGIC
    function _calculateProposalFee() private returns(uint256 _fee){
        return 2; // in bree
    }
    
    // check if proposal is active
    function _updatedProposalStatus(uint256 proposalId) private returns(bool _activeStatus){
        require(proposals[proposalId].status == Status.ACTIVE, "INACTIVE: Proposal is not active");
        // check if it is NOT in valid time frame
        if(block.timestamp > proposals[proposalId].endTime){
            // check if yesVotes is greater than noVotes AND yesTrustScores is greater/equal to noTrustScores
            if(proposals[proposalId].yesVotes > proposals[proposalId].noVotes && proposals[proposalId].yesTrustScores >= proposals[proposalId].noTrustScores)
                proposals[proposalId].status = Status.ACCEPTED;
            // check if noVotes is greater than yesVotes AND noTrustScores is greater than yesTrustScores
            else if(proposals[proposalId].noVotes > proposals[proposalId].yesVotes && proposals[proposalId].noTrustScores > proposals[proposalId].yesTrustScores)
                proposals[proposalId].status = Status.REJECTED;
            else // no resolution is met
            {
                proposals[proposalId].status = Status.ACTIVE;
                proposals[proposalId].startTime = proposals[proposalId].endTime;
                proposals[proposalId].endTime = proposals[proposalId].endTime.add(proposalPeriod);
            }
        }
    }
    
    
    // Vote for a proposal by paying fee in BREE
    function VOTE(uint256 proposalId, bool voteChoice) public notVoted(proposalId){
        
        // get the fee from user
        IERC20(BREE).transferFrom(msg.sender, address(this), _calculateVotingFee());
        
        // update the proposal status
        _updatedProposalStatus(proposalId);
        
        // require the status of the proposal with provided id is active
        require(proposals[proposalId].status == Status.ACTIVE, "INACTIVE: Proposal is not active");
        
        // check the vote choice and update the yesVotes OR noVotes AND yesTrustScores or noTrustScores
        _castVote(proposalId, voteChoice, _calculateVotingFee());
    }
    
    // TO DO LOGIC
    function _calculateVotingFee() private returns(uint256 _fee){
        return 1; // in bree
    }
    
    // check the vote choice and update the yesVotes OR noVotes AND yesTrustScores or noTrustScores
    function _castVote(uint256 proposalId, bool voteChoice, uint256 feePaid) private{
        if(voteChoice){ // true i.e. YES
            // increment yesVotes
            proposals[proposalId].yesVotes = proposals[proposalId].yesVotes.add(1);
            // add the trust score of the user to yesTrustScores
            proposals[proposalId].yesTrustScores = (proposals[proposalId].yesTrustScores).add(trustScore(voteChoice));
        } else{
            // increment noVotes
            proposals[proposalId].noVotes = proposals[proposalId].noVotes.add(1);
            // add the trust score of the user to noTrustScores
            proposals[proposalId].noTrustScores = (proposals[proposalId].noTrustScores).add(trustScore(voteChoice));
        }
        
        voters[msg.sender].proposalsVoted[proposalId].voted = true;
        voters[msg.sender].proposalsVoted[proposalId].choice = voteChoice;
        voters[msg.sender].proposalsVoted[proposalId].breePaid = feePaid;
        
        proposals[proposalId].totalBreePaid = proposals[proposalId].totalBreePaid.add(feePaid);
    }
    
    
    
    // TODO
    function claimEarnings() external{
        uint256 pendingEarnings;
        totalEarningsClaimed = totalEarningsClaimed.add(pendingEarnings);
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// PROPOSAL QUERY FUNCTIONS ////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function proposalStatus(uint256 proposalId) public view returns(string memory _status){
        if(proposals[proposalId].status == Status.ACCEPTED)
            return "Accepted";
        else if(proposals[proposalId].status == Status.REJECTED)
            return "Rejected";          
        else if(proposals[proposalId].status == Status.ACTIVE)
            return "Active";
        else return "Invalid proposal Id";
    }
    
    function proposalVoteCounts(uint256 proposalId) public view returns(uint256 _yesVotes, uint256 _noVotes){
        return(proposals[proposalId].yesVotes, proposals[proposalId].noVotes);
    }
    
    function proposalTrustScoreCounts(uint256 proposalId) public view returns(uint256 _yesTrustScore, uint256 _noTrustScore){
        return(proposals[proposalId].yesTrustScores, proposals[proposalId].noTrustScores);
    }
    
    function proposalTimeLeft(uint256 proposalId) public view returns(uint256 _timeLeft){
        if(proposals[proposalId].status == Status.ACTIVE){
            // check if it is NOT in valid time frame
            if(block.timestamp > proposals[proposalId].endTime){
                // check if yesVotes is greater than noVotes AND yesTrustScores is greater/equal to noTrustScores
                if(proposals[proposalId].yesVotes > proposals[proposalId].noVotes && proposals[proposalId].yesTrustScores >= proposals[proposalId].noTrustScores)
                    return 0;
                // check if noVotes is greater than yesVotes AND noTrustScores is greater than yesTrustScores
                else if(proposals[proposalId].noVotes > proposals[proposalId].yesVotes && proposals[proposalId].noTrustScores > proposals[proposalId].yesTrustScores)
                    return 0;
                else{ // no resolution is met
                    return (proposals[proposalId].endTime.add(proposalPeriod)).sub(proposals[proposalId].endTime);
                }
            } 
            else{
                return proposals[proposalId].endTime.sub(proposals[proposalId].startTime);
            }
        }
        else return 0;
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// VOTES QUERY FUNCTIONS ////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    function votesPaid(uint256 proposalId, address user) external view returns(string memory _choice, uint256 _votesPaid){
        if(voters[user].proposalsVoted[proposalId].choice)
            _choice = "yes";
        else
            _choice = "no";
        return (_choice, voters[user].proposalsVoted[proposalId].breePaid);
    }
    
    function claimableEarnings(uint256 proposalId, address user) external view returns(uint256){
        return 0;
    }
    
    function userTotalClaimedEarnings(uint256 proposalId, address user) external view returns(uint256){
        return 0;
    }
    
    function totalClaimedEarningsOfAllUsers() external view returns (uint256) {
        return totalEarningsClaimed;
    }
}