module Sporp

  VERSION = 'Sporp v0.1'

  MP4INFO = '/usr/local/bin/mp4info'
  MP4TAGS = '/usr/local/bin/mp4tags'

  ACOUSTID_META = 'recordings+releases+releasegroups+tracks+puids+compress'
  ACOUSTID_API_KEY = $APP_CONFIG.acoustid.api_key

  def self.is_audio_file? file
    [ 'm4a' ].include? Pathname.new(file).extname[1..-1]
  end

  def self.already_processed? file
    file = Pathname.new(file)
    m = `#{Sporp::MP4INFO} "#{file}"`.match(/^ Encoded with: (.+)$/)
    if m && m[1] == VERSION
      true
    else
      false
    end
  end

  def self.lookup_url duration, fingerprint
    "http://api.acoustid.org/v2/lookup?client=#{ACOUSTID_API_KEY}&meta=#{ACOUSTID_META}&duration=#{duration}&fingerprint=#{fingerprint}"
  end
end
