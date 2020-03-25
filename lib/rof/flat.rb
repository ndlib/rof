module ROF
  # Flat is our internal unit for representing a CurateND record.
  # It is conceptually, a PID along with a sequence of key-value pairs
  # where keys and values are strings, and keys may be repeated.
  class Flat
    attr_accessor :fields # do not access directly

    def initialize
      @fields = {}
    end

    def ==(other)
      return false unless self.class == other.class
      @fields == other.fields
    end

    def find_first(field_name)
      @fields.fetch(field_name, []).first
    end

    def find_all(field_name)
      @fields.fetch(field_name, [])
    end

    def each_field(&block)
      @fields.each(&block)
    end

    # add creats a new (field_name, value) entry.
    # nil or empty values will not be added.
    # if value is an array, many such pairs are created.
    # For special behavior, consider add_uniq()
    def add(field_name, value)
      value = value.reject { |x| x.nil? || x.empty? } if value.is_a?(Array)
      return if value.nil? || value.empty?
      v = @fields.fetch(field_name, [])
      @fields[field_name] = if value.is_a?(Array)
                              v + value
                            else
                              v << value
                            end
    end

    def add_uniq(field_name, value)
      add(field_name, value)
      @fields[field_name].uniq! unless @fields[field_name].nil?
    end

    def add_if_missing(field_name, value)
      add(field_name, value) if @fields[field_name].nil?
    end

    def delete_all(field_name)
      @fields.delete(field_name)
    end

    def set(field_name, value)
      delete_all(field_name)
      add(field_name, value)
    end

    def to_sexp
      s = "(record\n"
      @fields.keys.sort.each do |k|
        @fields[k].each do |vv|
          s << "  (#{k} #{vv})\n"
        end
      end
      s + ')'
    end

    def pretty_print(pp)
      pp.text to_sexp
    end

    def self.from_hash(h)
      result = Flat.new
      h.each do |k, v|
        next unless k.is_a?(String)
        v = Array.wrap(v)
        result.add(k, v)
      end
      result
    end

    def self.from_sexp(s)
      read_sexp(s).first
    end

    # read_sexp() parses one record out of s and returns
    # the pair [new Flat, rest of s]
    def self.read_sexp(s)
      # as we all learned, regexp cannot match balanced parens
      # so we're going to need to do it by hand
      # levels:
      #    0 -- outside of record
      #    1 -- inside record
      # >= 2 -- inside field
      level = 0
      result = Flat.new
      buffer = ''
      loop do
        before, paren, s = s.partition(/[()]/)
        case paren
        when '('
          buffer.concat(before + paren) if level >= 2
          level += 1
        when ')'
          buffer << before if level >= 2
          buffer << paren if level >= 3 # don't consume parens for higher levels
          level -= 1
          case level
          when 1
            name, value = buffer.split(/\s+/, 2)
            result.add(name.strip, value.strip)
            buffer = ''
          when 0
            return result, s
          end
        else
          return result, 'unmatched parens'
        end
      end
    end
  end
end
