module RemoteStubs
  def load_fixture(name)
    path = "#{Rails.root}/spec/fixtures/#{name}"
    File.read(path)
  end
end
