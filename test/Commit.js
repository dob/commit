contract('Commit', function(accounts) {
    it("should initilaize the contract correctly", function(done) {
	var cnt;
	Commit.new({from: accounts[0]}).then(function(result) {
	    cnt = result;
	    return cnt.rewardBalance.call();
	}).then(function(result) {
	    assert.strictEqual(result.toNumber(), 0, "Reward balance should start at zero");
	    return cnt.ownershipRakeDivisor.call();
	}).then(function(result) {
	    assert.equal(result.toNumber(), 5, "Rake divisor not set");
	    return cnt.totalDonated.call();
	}).then(function(result) {
	    assert.equal(result.toNumber(), 0, "Total donation should start at zero");
	    done();
	}).catch(done);
    });


    it("should update the user's balance if they makes a valid commitment", function(done) {
	var cnt;
	var user = accounts[1];
	
	Commit.new({from:accounts[0]}).then(function(result) {
	    cnt = result;
	    return cnt.newCommitment("Commit to github every day", 5, 5, {from: user, value: web3.toWei(5, "ether")});
	}).then(function(result) {
	    return cnt.getBalance.call({from: user});
	}).then(function(result) {
	    assert.equal(result.toNumber(), web3.toWei(5, "ether"), "Users balance should equal what they put in");
	    done();
	}).catch(done);
    });
    
});
