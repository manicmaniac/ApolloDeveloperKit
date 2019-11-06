import ApolloCachePretender from '../ApolloCachePretender';

describe('ApolloCachePretender', () => {
    describe('#extract', () => {
        it('returns some object', () => {
            const cache = new ApolloCachePretender();
            expect(cache.extract()).toStrictEqual({});
        });

        it('invokes the callback', done => {
            const cache = new ApolloCachePretender(() => {
                done();
            });
            cache.extract();
        });
    });
});