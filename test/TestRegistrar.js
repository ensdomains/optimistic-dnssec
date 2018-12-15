const Registrar = artifacts.require('./Registrar.sol');
const DNSSEC = artifacts.require('./mocks/DummyDNSSEC.sol');
const ENS = artifacts.require('./ENSRegistry.sol');

const utils = require('./helpers/Utils.js');
const namehash = require('eth-ens-namehash');

contract('Registrar', function(accounts) {

    let registrar, dnssec, ens;
    const stake = 10;
    const cooldown = 3600;

    beforeEach(async function() {
        node = namehash.hash('eth');

        ens = await ENS.new();
        dnssec = await DNSSEC.new();
        registrar = await Registrar.new(ens.address, dnssec.address, stake, cooldown);

        await ens.setSubnodeOwner(0, web3.sha3('eth'), registrar.address, {from: accounts[0]});
        await ens.setOwner(0, registrar.address);
    });

    describe('submit', async () => {

        it('should fail to submit when not enough stake is sent', async () => {
            try {
                await registrar.submit('0x0', '0x0', accounts[0], {value: stake});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('did not fail');
        });

    });

});