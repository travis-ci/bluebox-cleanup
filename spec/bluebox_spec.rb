describe Bluebox do
  it 'autoloads Cleanup' do
    expect(Bluebox::Cleanup).to_not be_nil
  end

  it 'autoloads CleanupRunner' do
    expect(Bluebox::CleanupRunner).to_not be_nil
  end

  it 'autoloads Config' do
    expect(Bluebox::Config).to_not be_nil
  end

  it 'has a logger' do
    expect(Bluebox.logger).to_not be_nil
  end
end
