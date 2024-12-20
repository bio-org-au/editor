# lib/factory_bot_generator.rb
class FactoryBotGenerator
  def initialize(structure_file:, output_dir:)
    @structure_file = structure_file
    @output_dir = output_dir
  end

  def generate_factories
    structure_content = File.read(@structure_file)
    tables = extract_tables(structure_content)

    tables.each do |table|
      generate_factory_file(table)
    end
  end

  private

  def extract_tables(content)
    # Parse each CREATE TABLE statement for tables under the 'public' schema
    content.scan(/CREATE TABLE public\.(\w+).*?\((.*?)\);/m).map do |table_name, columns_definition|
      parse_table(table_name, columns_definition)
    end
  end

  def parse_table(table_name, columns_definition)
    columns = columns_definition.scan(/(\w+) (\w+)(?:\s+[^,]*)(?: DEFAULT ([^,]+))?/).map do |col|
      { name: col[0], type: col[1], default: col[2] }
    end
    { name: table_name, columns: columns }
  end

  def generate_factory_file(table)
    table_name = table[:name]
    factory_name = table_name.singularize
    factory_file = File.join(@output_dir, "#{factory_name}.rb")

    File.open(factory_file, 'w') do |file|
      file.puts "FactoryBot.define do"
      file.puts "  factory :#{factory_name} do"

      table[:columns].each do |column|
        next if skip_column?(column[:name])

        file.puts generate_attribute(column)
      end

      file.puts "  end"
      file.puts "end"
    end

    puts "Factory for #{table_name} written to #{factory_file}"
  end

  def skip_column?(column_name)
    column_name == 'id' || column_name.end_with?('_at') # Skip primary keys and timestamps
  end

  def generate_attribute(column)
    attr_name = column[:name]
    default_value = column[:default]&.gsub(/'|::\w+/, '')
    attr_type = column[:type].downcase

    value = case attr_type
            when /int|serial/ then default_value || 1
            when /char|text/ then default_value || "\"Sample #{attr_name.humanize}\""
            when /bool/ then default_value || true
            when /timestamp|date|time/ then "Time.current"
            when /uuid/ then "SecureRandom.uuid"
            when /jsonb|json/ then "{}"
            when /array/ then "[]"
            else default_value || "\"Default #{attr_name}\""
            end

    "    #{attr_name} { #{value} }"
  end
end
