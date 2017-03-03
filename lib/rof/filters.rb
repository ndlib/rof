Dir.glob(File.expand_path('../filters/*.rb', __FILE__)).each do |filename|
  require filename
end

module ROF
  module Filters
  end
end
