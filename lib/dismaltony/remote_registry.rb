module DismalTony
  class RemoteRegistry
    include Enumerable
    @@remotes = []

    def self.load_remotes_from(directory)
      found_files = (Dir.entries directory).reject { |e| !(e =~ /.+\.rb/) }
      found_files.each do |file|
        load "#{directory}/#{File.basename(file)}"
      end
    end

    def self.load_remotes!(dir = '/')
      self.load_remotes_from(dir)
    end

    def self.remotes
      @@remotes
    end

    def self.register(remote)
      @@remotes << remote
    end

    def self.each()
      @@remotes.each
    end

    def self.[](par)
      par = Regexp.new(par, Regexp::IGNORECASE) if par.is_a? String
      @@remotes.select { |h| h.subject =~ par}
    end

    def self.group(par)
      @@remotes.select do |h| 
        next unless h.responds_to?('group')
        h.group == par
      end
    end

    def self.groups
      (@@remotes.map { |h| (h.group if h.responds_to('group')) || ("none")}).uniq
    end

  end
end