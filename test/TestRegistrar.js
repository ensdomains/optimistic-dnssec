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

    describe('challenge', async () => {

        it('should fail to challenge when period has expired', async () => {
            await registrar.submit(dns.hexEncodeName('foo.test.'), '0x0', accounts[1], {value: stake});

            await utils.advanceTime(cooldown + 1);

            try {
                await registrar.challenge(dns.hexEncodeName('foo.test.'), '0x0');
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('did not fail');
        });

        it('should fail to challenge when proofs do not match', async () => {
            await registrar.submit(dns.hexEncodeName('foo.test.'), '0x0', accounts[1], {value: stake});

            try {
                await registrar.challenge(dns.hexEncodeName('foo.test.'), '0x1');
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('did not fail');
        });

        // @todo should fail when proof is valid

//        it('should successfully challenge when proof is invalid', async () => {
//
//            // @todo requires proper data
//
//            await registrar.submit(dns.hexEncodeName('foo.test.'), '0x0', accounts[1], {value: stake});
//
//            await registrar.challenge(dns.hexEncodeName('foo.test.'), '0x0');
//        });
    });

    describe('commit', async () => {

        it('should fail to commit when cooldown period has not expired', async () => {
            await registrar.submit(dns.hexEncodeName('foo.test.'), '0x0', accounts[1], {value: stake});

            try {
                await registrar.commit(dns.hexEncodeName('foo.test.'));
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('did not fail');
        });

        // @todo should fail when challenged

        it('should successfully commit when cooldown period has expired', async () => {
            await registrar.submit(dns.hexEncodeName('foo.test.'), '0x0', accounts[1], {value: stake});

            await utils.advanceTime(cooldown + 1);

            await registrar.commit(dns.hexEncodeName('foo.test.'));

            assert.equal(await ens.owner(namehash.hash('foo.test')), accounts[1]);
        });

    });
});