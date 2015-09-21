describe Bluebox::Cleanup do
  let(:argv) { [] }
  let(:output) { StringIO.new }

  before(:each) do
    $stdout = output
    ENV['BLUEBOX_API_KEY'] = 'api-key'
    ENV['BLUEBOX_CUSTOMER_ID'] = 'customer-id'
    ENV['TRAVIS_JOB_STATE_URL'] = 'job-state-url'
    ENV['BLUEBOX_CLEANUP_FOREVER'] = nil
  end

  after(:each) { $stdout = STDOUT }

  it 'has a log' do
    expect(subject.send(:log)).to_not be_nil
  end

  context 'when asked for help' do
    let(:argv) { %w(--help) }

    it 'shows help' do
      described_class.main(argv)
      expect(output.string).to match(/Usage:/)
    end

    it 'returns 0' do
      expect(described_class.main(argv)).to be 0
    end
  end

  %w(
    BLUEBOX_API_KEY
    BLUEBOX_CUSTOMER_ID
    TRAVIS_JOB_STATE_URL
  ).each do |env_var|
    context "when #{env_var} is not defined" do
      before(:each) { ENV.delete(env_var) }

      it 'shows help' do
        described_class.main(argv)
        expect(output.string).to match(/Usage:/)
      end

      it 'returns 1' do
        expect(described_class.main(argv)).to be 1
      end
    end
  end

  context 'with a fake runner' do
    let(:runner) do
      double('runner').tap do |runner|
        class << runner
          def run
            @ran = true
          end

          attr_reader :ran
        end
      end
    end

    before(:each) do
      allow(Bluebox::CleanupRunner).to receive(:new).and_return(runner)
    end

    it 'runs the runner' do
      described_class.main(argv)
      expect(runner.ran).to be true
    end

    it 'returns 0' do
      expect(described_class.main(argv)).to be 0
    end
  end

  context 'with a real runner', integration: true do
  end
end
