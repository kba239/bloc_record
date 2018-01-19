require 'sqlite3'
require 'pg'

 module Connection
  def connection
    BlocRecord.database == :sqlite3 ? @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    BlocRecord.database == :pg ? @connection ||= PG.connect(dbname: BlocRecord.database_filename)
  end
end
