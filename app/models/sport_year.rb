class SportYear
  attr_reader :year

  def initialize(date = Date.current)
    @date = date
    @year = (@date.month >= 9 ? @date.year : @date.year - 1)
  end

  def start_date
    Date.new(@year, 9, 1)
  end

  def end_date
    Date.new(@year + 1, 8, 31)
  end

  def range
    start_date..end_date
  end

  def to_s
    "#{@year}/#{@year + 1}"
  end

  def self.current
    new(Date.current)
  end

  def self.end_date_for(date)
    new(date).end_date
  end
end
