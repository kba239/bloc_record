require 'sqlite3'

module Selection

  def find(*ids)
    return find_one(ids.first) if ids.length == 1

    puts "One or more of these values is not a valid ID." unless ids.all? { |id| id.is_a?(Integer) && id > 0 }

    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id IN (#{ids.join(",")});
    SQL

    rows_to_array(rows)
  end

  def find_one(id)

    puts "One or more of these values is not a valid ID." unless ids.all? { |id| id.is_a?(Integer) && id > 0 }

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL
    init_object_from_row(row)
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def take(num=1)
    return take_one unless num > 1

    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT #{num};
    SQL

    rows_to_array(rows)
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def find_each(options = {})
    start = options[:start]
    batch_size = options[:batch_size]
    if start != nil && batch_size != nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size} OFFSET #{start};
      SQL
    elsif start == nil && batch_size != nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size};
      SQL
    elsif start != nil && batch_size == nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        OFFSET #{start};
      SQL
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table};
      SQL
    end

    rows.each do |row|
      yield init_object_from_row(row)
    end
  end

  def find_in_batches(options = {})
    start = options[:start]
    batch_size = options[:batch_size]
    if start != nil && batch_size != nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size} OFFSET #{start};
      SQL
    elsif start == nil && batch_size != nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size};
      SQL
    elsif start != nil && batch_size == nil
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        OFFSET #{start};
      SQL
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table};
      SQL
    end

    row_array = rows_to_array(rows)
    yield(row_array)
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Symbol
        expression = args.first.to_s
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end


  def order(*args)
    orderedArray = []
    args.each do |arg|
      case arg
      when String
        orderedArray << arg
      when Symbol
        orderedArray << arg.to_s
      when Hash
        orderedArray << arg.map{|key, value| "#{key} #{value}"}
      end
    end

    order = orderedArray.join(",")
    puts order

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        key = args.first.keys.first
        value = args.first[key]
        puts "#{key}, #{value}"
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id
          INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id
        SQL
      end
    end

    rows_to_array(rows)
  end

  private

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end

  def method_missing(method_name, *args)
    if method_name.match(/find_by_/)
      attribute = method_name.to_s.split('find_by_')[1]
      columns.include?(attribute) ? find_by(attribute, *args) : puts "#{attribute} does not exist in the database."
    else
      super
    end
  end
end
