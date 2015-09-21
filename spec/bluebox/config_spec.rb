describe Bluebox::Config do
  it 'exposes a config at the module level' do
    expect(Bluebox.config).to_not be nil
    expect(Bluebox.config).to_not be_empty
  end
end
