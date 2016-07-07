contract owned {
    address public owner;

    function owned() {
	owner = msg.sender;
    }

    modifier onlyOwner {
	if (msg.sender != owner) throw;
	_
    }

    function transferOwnership(address newOwner) onlyOwner {
	owner = newOwner;
    }
    
}

contract Commit is Owned {

    uint public rewardBalance;
    float32 public ownershipRake;
    address public charityAddress;
    uint public totalDonated;    // Keep track of total donation over time

    mapping (address => Commitment) public commitments;
    address[] userAddresses;   // Need to keep a list of all user addresses since you can't iterate over a mapping

    event CommitmentAdded(commitmentLabel, address user, uint value, uint occurrences, uint deadline);
    event CommitmentSucceeded(commitmentLabel, address user, uint value, uint occurrences);
    event CommitmentFailed(commitmentLabel, address user, uint value);
    event CommitReported(commitmentLabel, address user);
    event DonatedToCharity(address charity, uint value);

    struct Commitment {
	address user;
	uint deposit;              // Amount the user put in
	uint balance;              // Amount left remaining in this user's pot
	uint deadline;             // Date by which they must hit their commitment
	string label;              // String that represents their goal for display purposes
	uint targetOccurrences;     // Target number of occurances in their goal
	uint currentOccurrences;    // Progress so far towards their goal
	bool active;               // Is the commitment still active?
	bool succeeded;            // User hit their commitment
	bool failed;               // User didn't hit their commitment
    }
   
    function Commit() {
	// constructor
	rewardBalance = 0;
	ownershipRake = 0.2;
	totalDonated = 0;
	charityAddress = "";       // TBD, fill in address of donation charity
    }

    function donate() onlyOwner {
	// send rewardBalance to the charityAddress
	charityAddress.send(rewardBalance);

	// Check if success on the send before zeroing the balance?
	totalDonated += rewardBalance;
	DonatedToCharity(charityAddress, rewardBalance);
	rewardBalance = 0;
    }

    function checkFailures() onlyOwner {
	// Run through the list of commitments, and check all active
	// ones to see if they have failed. If so, mark them as failed,
	// inactive, and transfer the balance between the owner and the
	// reward pot
	for (uint i = 0; i < userAddresses.length; i++) {
	    c = commitments[userAddresses[i]];
	    if (c.active == true && isPastDeadline(c) == true) {
		failCommitment(c);
	    }
	}
    }

    /* User calls this function to commit to doing something described by commitmentLabel
       daysUntilDeadline times*/
    function newCommitment (
	string commitmentLabel,
	uint targetOccurrences,
	uint daysUntilDeadline
    )
    returns (bool success)
    {
	if (msg.value == 0) throw;         // Must put down a deposit
	if (daysUntilDeadline <= 0) throw; // Must have a future deadline
	if (targetOccurrences <= 0) throw;  // Must have a goal number of occurrences
	if (targetOccurrences > daysUntilDeadline) throw; // Can't succeed at something more times than you have days right now.

	// Check to see if there's already a commitment for this user that is active
	Commitment currentForUser = commitments[msg.sender];
	if (currentForUser != 0 &&  currentForUser.active == true) throw;

	// Add this user to our user list if they don't exist
	addUserToListIfMissing(msg.sender);

	// Generate a new commitment
	Commitment c;
	c.user = msg.sender;
	c.deposit = msg.value;
	c.balance = c.deposit;   // Balance starts equal to initial deposit
	c.deadline = now + daysUntilDeadline * 1 days;
	c.label = commitmentLabel;
	c.targetOccurrences = targetOccurrences;
	c.currentOccurrences = 0;
	c.active = true;
	c.succeeded = false;
	c.failed = false;

	commitments[msg.sender] = c;

	CommitmentAdded(c.label, c.user, c.deposit, c.targetOccurrences, c.deadline);
	return true;
    }

    function submitOccurrence() returns (bool success) {
	Commitment c = commitments[msg.sender];
	if (c == 0 || c.active == false) throw;  // Couldn't find any commitment for this user

	c.currentOccurrences++;
	if (isPastDeadline(c)) {
	    // Split pot to charity and owner, update status, report loss
	    failCommitment(c);
	    return false;
	}

	CommitReported(c.label, msg.sender)
	if (isWinner(c) == true) {
	    // Report victory!
	    succeedCommitment(c);
	} else {
	    // Pay out proactively
	    payoutPartial(c);
	}
	return true;
    }    

    function () {
	throw;
    }


    // Can these be private?

    function isPastDeadline(Commitment c) private returns (bool failure) {
	if (now > c.deadline) {
	    failure = true;
	} else {
	    failure = false;
	}
    }

    function isWinner(Commitment c) private returns (bool winner) {
	if (c.currentOccurrences >= c.targetOccurrences && isPastDeadline(c) == false) {
	    winner = true;
	} else {
	    winner = false;
	}
    }

    // Update the commitment, pay out the charity and owner
    function failCommitment(Commitment c) private {
	// Do you need a mutex around these?
	uint balance = c.balance;

	ownersCut = balance * ownershipRake;
	rewardCut = balance - ownersCut;

	owner.send(ownersCut);
	rewardBalance += rewardCut;

	c.balance = 0;
	c.active = false;
	c.succeeded = false;
	c.failed = true;

	CommitmentFailed(c.label, c.user, balance);
    }

    function succeedCommitment(Commitment c) private {
	c.active = false;
	c.succeeded = true;
	c.failed = false;
	c.user.send(c.balance);
	c.balance = 0;

	CommitmentSucceeded(c.label, c.user, c.deposit, c.targetOccurrences)
    }

    // Pay out one event's worth of accomplishment bounty
    function payoutPartial(Commitment c) private {
	uint partialPayout = c.deposit / c.targetOccurrences;
	c.user.send(partialPayout);
	c.user.balance -= partialPayout;
    }

    function addUserToListIfMissing(address addr) private {
	bool exists = false;
	for (uint i = 0; i < userAddresses.length; i++) {
	    address a = userAddresses[i];
	    if (addr == a) {
		exists = true;
	    }
	}

	if (exists == false) {
	    uint i = userAddresses.length++;
	    users[i] = addr;
	}
    }
}
