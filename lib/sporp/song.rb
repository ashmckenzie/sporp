module Sporp
  class Song

    attr_reader :file, :response

    def initialize file, raw
      @file = Pathname.new(file)
      @response = Hashie::Mash.new(JSON.parse(raw))
    end

    def self.lookup file
      file = Pathname.new(file)
      output = `./fpcalc "#{file.to_s}"`
      duration = output.match(/^DURATION=(.+)$/)[1]
      fingerprint = output.match(/^FINGERPRINT=(.+)$/)[1]
      response = HTTParty.get(Sporp::lookup_url(duration, fingerprint))
      if response.code == 200 && !JSON.parse(response.body)['results'].empty?
        return self.new(file, response.body)
      else
        raise "Unable to identify song for '#{file}'"
      end
    end

    def artist
      @artist ||= recording.artists.first.name
    end

    def album
      @album ||= recording.releasegroups.first.title
    end

    def title
      @title ||= recording.title
    end

    def track_number
      @track_number ||= recording.releasegroups.first.releases.first.mediums.first.tracks.first.position
    end

    def track_count
      @track_count ||= recording.releasegroups.first.releases.first.track_count
    end

    def acoustid_id
      @acoustid_id ||= response.results.first.id
    end

    def acoustid_track_url
      @acoustid_track_url ||= "http://acoustid.org/track/#{acoustid_id}"
    end

    def music_brainz_id
      @music_brainz_id ||= response.results.first.recordings.first.id
    end

    def music_brainz_recording_url
      @music_brainz_recording_url ||= "http://musicbrainz.org/recording/#{music_brainz_id}"
    end

    def rename!
      if new_file_name == file
        $logger.warn "File '#{file}' and new file '#{new_file_name}' are the same"
      else
        file.rename(new_file_name) ? true : false
      end
    end

    def new_file_name
      @new_file_name ||= Pathname.new(File.join(file.dirname.to_s, "%02d" % track_number + " #{title}#{file.extname}"))
    end

    def to_s
      id = "#<%s:0x%08x>" % [ self.class.to_s, (self.object_id * 2) ]
      "#{id} artist=#{artist}, album=#{album}, title=#{title}, track_number=#{track_number}"
    end

    def tag!
      `#{Sporp::MP4TAGS} -artist "#{artist}" "#{file.to_s}"`
      `#{Sporp::MP4TAGS} -albumartist "#{artist}" "#{file.to_s}"`
      `#{Sporp::MP4TAGS} -album "#{album}" "#{file.to_s}"`
      `#{Sporp::MP4TAGS} -song "#{title}" "#{file.to_s}"`
      `#{Sporp::MP4TAGS} -track "#{track_number}" "#{file.to_s}"`
      `#{Sporp::MP4TAGS} -tracks "#{track_count}" "#{file.to_s}"`
      `#{Sporp::MP4TAGS} -type 1 "#{file.to_s}"`
      `#{Sporp::MP4TAGS} -tool "#{VERSION}" "#{file.to_s}"`
      true
    end

    def tag_and_rename!
      tag!
      rename!
    end

    private

    def recording
      @recording ||= response.results.first.recordings.first
    end
  end
end
