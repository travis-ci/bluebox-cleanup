# lifted from https://gist.github.com/ryandotsmith/5343120
# with modifications
module L2metLog
  LOG_LEVELS = {
    debug: 10,
    info: 20,
    warn: 30,
    error: 40,
    fatal: 50
  }

  class << self
    attr_writer :default_log_level

    def default_log_level
      @default_log_level ||= :info
    end
  end

  def log(data)
    data[:level] ||= :info
    unless log_level_allowed?(data[:level])
      yield if block_given?
      return
    end
    data[:time] ||= Time.now.utc
    result = nil
    name = nil
    if data.key?(:measure)
      name = data.delete(:measure).insert(0, ENV['APP_NAME'] + '.')
    end
    if block_given?
      start = Time.now
      result = yield
      elapsed = (Time.now.to_f - start.to_f) * 1000
      data.merge!("measure.#{name}" => elapsed.round)
    end
    out = ['time', data.delete(:time).iso8601].join('=') << ' '
    data.reduce(out) do |s, (key, value)|
      value = if value.is_a?(String)
                "\"#{value}\""
              elsif value.respond_to?(:iso8601)
                value.iso8601
              else
                value
              end
      s << [key, value].join('=') << ' '
    end
    $stdout.puts(out)
    result
  end

  attr_writer :log_level

  def log_level
    @log_level ||= L2metLog.default_log_level
  end

  private

  def log_level_allowed?(level)
    log_level_int(level) >= log_level_int(log_level)
  end

  def log_level_int(level)
    LOG_LEVELS.fetch(level.downcase.to_sym)
  end
end
