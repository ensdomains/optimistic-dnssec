const Registrar = artifacts.require('./Registrar.sol');
const DNSSEC = artifacts.require('./mocks/DummyDNSSEC.sol');
const ENS = artifacts.require('./ENSRegistry.sol');

const utils = require('./helpers/Utils.js');
const namehash = require('eth-ens-namehash');
const dns = require('../lib/dns.js');

contract('Registrar', function(accounts) {

    let registrar, dnssec, ens;
    const stake = 10;
    const cooldown = 3600;

    beforeEach(async function() {
        node = namehash.hash('eth');

        ens = await ENS.new();
        dnssec = await DNSSEC.new();
        registrar = await Registrar.new(ens.address, dnssec.address, cooldown, stake);

        await ens.setSubnodeOwner(0, web3.sha3('test'), registrar.address);
    });

    describe('submit', async () => {

        it('should fail to submit when not enough stake is sent', async () => {
            try {
                await registrar.submit(dns.hexEncodeName('foo.test.'), '0x0', accounts[0], {value: stake / 2});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('did not fail');
        });

        it('should succeed when submitting with a valid stake and name', async () => {
            await registrar.submit(dns.hexEncodeName('foo.test.'), '0x0', accounts[1], {value: stake});


            let record = await registrar.records.call(namehash.hash('foo.test'));

            assert.equal(record[0], accounts[0]);
            assert.equal(record[1], accounts[1]);
        });

    });

});