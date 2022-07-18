require 'json'
require 'net/http'


# TODO make this into a module
def remote_checksums_for_gem(gem_name, gem_version)
  response = Net::HTTP.get_response(URI(
    "https://rubygems.org/api/v1/versions/#{gem_name}.json"
  ))

  if response.code == '200'
    gem_candidates = JSON.parse(response.body, symbolize_names: true)
    gem_candidates.select! { |g| g[:number] == gem_version.to_s }

    gem_candidates.map {
      |g| {:name => gem_name, :version => gem_version, :platform => g[:platform], :checksum => g[:sha]}
    }
  elsif response.code == '404'
    []
  end
end


def local_checksums_for_gem(gem_name, gem_version, checksum_file)
  local_checksums = JSON.parse(File.open(checksum_file).read, symbolize_names: true)
  local_checksums.detect { |g| g[:name] == gem_name && g[:version] == gem_version.to_s }[:checksum]
end


def validate_gem_checksum(gem_name, gem_version, gem_platform, checksum_file)
  remote_checksums = remote_checksums_for_gem(gem_name, gem_version)
  if remote_checksums.nil? || remote_checksums.empty?
    $stderr.puts "#{gem_name} #{gem_version} not found on rubygems, skipping"
    return true
  end

  local_checksums = local_checksums_for_gem(gem_name, gem_version, checksum_file)

  local_platform_checksum = local_checksums.find { |g| g[:name] == gem_name && g[:platform] == gem_platform.to_s }
  remote_platform_checksum = remote_checksums.find { |g| g[:name] == gem_name && g[:platform] == gem_platform.to_s }

  if local_platform_checksum[:checksum] == remote_platform_checksum[:checksum]
    true
  else
    $stderr.puts "Gem #{gem_name} #{gem_version} #{gem_platform} failed checksum verification"
    $stderr.puts "LOCAL:  #{local_platform_checksum[:checksum]}"
    $stderr.puts "REMOTE: #{remote_platform_checksum[:checksum]}"
    return false
  end
end


def write_checksums_to_file(checksums, checksum_file)
  local_checksums = []
  File.open(checksum_file, 'r') do |f|
    local_checksums = JSON.parse(f.read, symbolize_names: true)
  end

  # puts 'LOCAL'
  # puts local_checksums
  # remove existing gem entries for previous gem versions
  local_checksums.reject! { |g| g[:name] == checksums.first[:name]}
  local_checksums.concat(checksums)

  # puts 'INCOMING'
  # puts checksums

  File.open(checksum_file, 'w') do |f|
    f.write JSON.pretty_generate(local_checksums)
  end
end
