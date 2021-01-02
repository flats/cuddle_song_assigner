require 'ostruct'

# constraints:

# 1. no song should have a sound played on it more than once
# 2. no person should have to play a sound more than once
# 3. people should wait as long as possible to play their own instrument

class Instrument
  attr_accessor :name
  @@all = []

  def initialize name
    @name = name
    @@all << self
  end

  def self.all
    @@all
  end
end

class Person
  attr_accessor :name, :instruments, :already_played_instruments, :already_played_songs
  @@all = []

  def initialize name, instruments
    @name = name
    @instruments = instruments
    @already_played_instruments = []
    @already_played_songs = []
    @@all << self
  end

  def self.all
    @@all
  end

  def clear_songs_and_instruments
    @already_played_instruments = []
    @already_played_songs = []
  end

  def unplayed_and_not_own_instruments available_instruments
    available_instruments - already_played_instruments - instruments
  end

  def unplayed_instruments available_instruments
    available_instruments - already_played_instruments
  end

  def unplayed_songs available_songs
    available_songs - already_played_songs
  end
end

class Song
  attr_accessor :name, :already_used_instruments
  @@all = []

  def initialize name
    @name = name
    @already_used_instruments = []
    @@all << self
  end

  def self.all
    @@all
  end

  def clear_instruments
    @already_used_instruments = []
  end

  def unused_instruments available_instruments
    available_instruments - @already_used_instruments
  end
end

class Schedule
  attr_accessor :name, :assignments

  def initialize name
    @assignments = []
    @name = name
    @songs = Song.all.clone.shuffle
    @instruments = Instrument.all.clone.shuffle
  end

  def assign_for person
    song = person.unplayed_songs(@songs).sample
    return false if song.nil?
    person.already_played_songs << song
    @songs.delete(song)

    instrument = (person.unplayed_and_not_own_instruments(@instruments) || person.unplayed_instruments(@instruments) & song.unused_instruments(@instruments)).sample
    return false if instrument.nil?
    person.already_played_instruments << instrument
    song.already_used_instruments << instrument unless song.nil?
    @instruments.delete(instrument)

    assignments << OpenStruct.new(person: person, song: song, instrument: instrument)
    true
  end

  def clear_assignments
    @assignments = []
  end

  def print
    puts "#{name}:\n\n"
    assignments.group_by { |assignment| assignment.person.name }.each do |person_name, assignments|
      name_char_length = person_name.length + 2
      puts "#{person_name}: #{' ' * (13 - name_char_length)}#{assignments[0].song&.name}, #{assignments[0].instrument&.name}\n"
      puts "#{assignments[1].song&.name}, #{assignments[1].instrument&.name}".prepend(' ' * 13)
    end
    puts "\n"
  end
end

dave = Person.new 'Dave', [Instrument.new('percussion')]
ben = Person.new 'Ben', [Instrument.new('guitar')]
cole = Person.new 'Cole', [Instrument.new('trumpet'), Instrument.new('muted trumpet'), Instrument.new('op-1')].shuffle
christopher = Person.new 'Christopher', [Instrument.new('pump organ'), Instrument.new('yamaha #1'), Instrument.new('yamaha #2')].shuffle
alec = Person.new 'Alec', [Instrument.new('bass clarinet'), Instrument.new('flute')].shuffle
kristen = Person.new 'Kristen', [Instrument.new('270 #1'), Instrument.new('270 #2')].shuffle
keys = %w(a b-flat b c c-sharp d d-sharp e f f-sharp g a-flat)
keys.map do |name|
  Song.new name
end

statuses = []
schedules = []

puts 'start'

until (
  statuses.length > 0 && statuses.flatten.all? { |result| result == true }
)
  statuses = []
  schedules = [Schedule.new('Week 1'), Schedule.new('Week 2'), Schedule.new('Week 3'), Schedule.new('Week 4')]

  Person.all.each(&:clear_songs_and_instruments)
  Song.all.each(&:clear_instruments)

  schedules.each do |schedule|
    statuses << Person.all.shuffle.map do |person|
      first_result = schedule.assign_for person
      second_result = schedule.assign_for person
      first_result && second_result
    end
  end
end

# schedules.each do |schedule|
#   Person.all.shuffle.map do |person|
#     schedule.assign_for person
#     schedule.assign_for person
#   end
# end

schedules.each(&:print)

exit
