contract('Commit', function(accounts) {
    it("should initilaize the contract correctly", function(done) {
	Commit.new({from: accounts[0]}).then(function(result) {
	    contract = result;
	    return contract.rewardBalance.call();
	}).then(function(result) {
	    assert.strictEqual(result.toNumber(), 0, "Reward balance should start at zero");
	    return contract.ownershipRakeDivisor.call();
	}).then(function(result) {
	    assert.equal(result.toNumber(), 5, "Rake divisor not set");
	    return contract.totalDonated.call();
	}).then(function(result) {
	    assert.equal(result.toNumber(), 0, "Total donation should start at zero");
	    done();
	}).catch(done);
    });
});
