describe Bluebox::CleanupRunner do
  it 'has a log' do
    expect(subject.send(:log)).to_not be nil
  end

  it 'has a default batch size of 20' do
    expect(subject.send(:batch_size)).to be 20
  end

  it 'has no travis client by default' do
    expect(subject.send(:travis_client)).to be nil
  end

  it 'has no bluebox client by default' do
    expect(subject.send(:bluebox_client)).to be nil
  end

  context 'with fake travis and bluebox clients' do
    let :travis_client do
      double('travis_client').tap do |client|
        allow(client).to receive(:get).and_return(states_response)
      end
    end

    let :states_response do
      double(
        'states',
        body: JSON.dump(
          data: [
            {
              id: '00',
              state: 'created'
            },
            {
              id: '01',
              state: 'passed'
            }
          ]
        )
      )
    end

    let :bluebox_client do
      double('bluebox_client', servers: bluebox_servers).tap do |client|
        allow(client).to receive(:destroy_block)
      end
    end

    let :bluebox_servers do
      [
        double(
          'testing-server0',
          hostname: 'testing-worker-linux-00.example.com',
          id: '881f8d16-23a3-4e1a-ac57-aa2ea4428c10'
        ),
        double(
          'testing-server1',
          hostname: 'testing-worker-linux-01.example.com',
          id: '2419ca29-30e9-4b8a-8fb0-52fb5cbda9e0'
        ),
        double(
          'worker-server0',
          hostname: 'worker-linux-00.example.com',
          id: '346aca0d-9eef-430b-9a92-e852bbaed0fd'
        )
      ]
    end

    subject do
      described_class.new(
        travis_client: travis_client,
        bluebox_client: bluebox_client
      )
    end

    it 'returns 0' do
      expect(subject.run).to eql 0
    end

    context 'when there are no states' do
      let(:states_response) { double('states', body: '{}') }

      it 'returns 0' do
        expect(subject.run).to eql 0
      end
    end
  end

  context 'with real travis and bluebox clients', integration: true do
  end
end
