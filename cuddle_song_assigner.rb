require 'ostruct'
# require 'pry'

# constraints:

# 1. no song should have a sound played on it more than once
# 2. no person should have to play a sound more than once
# 3. people should wait as long as possible to play their own instrument

class Instrument
  attr_accessor :name, :person
  @@all = []

  def initialize name
    @name = name
    @@all << self
  end

  def self.all
    @@all
  end

  def self.instruments_for person
    self.all.select do |instrument|
      instrument.person == person
    end
  end
end

class Person
  attr_accessor :name, :instruments, :already_played_instruments, :already_played_songs
  @@all = []

  def initialize name, instruments
    @name = name
    instruments.each do |inst|
      inst.person = self
    end
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
  attr_accessor :name, :already_used_instruments, :assigned
  @@all = []

  def initialize name
    @name = name
    @already_used_instruments = []
    @assigned = false
    @@all << self
  end

  def self.all
    @@all
  end

  def self.all_unassigned
    self.all.select { |song| song.assigned == false }
  end

  def self.clear_all_assigned
    self.all.each { |song| song.assigned = false}
  end

  def clear_instruments
    @already_used_instruments = []
  end

  def unused_instruments available_instruments
    available_instruments - @already_used_instruments
  end

  def unused_instruments_by_person available_instruments
    all_used_people_instrumeents = @already_used_instruments.map do |inst|
      Instrument.instruments_for(inst.person)
    end.flatten

    (available_instruments - all_used_people_instrumeents).shuffle
  end
end

class Schedule
  attr_accessor :name, :assignments

  def initialize name
    @assignments = []
    @name = name
    @instruments = Instrument.all.clone.shuffle
  end

  def assign_for person
    return false unless song = assign_song(person)

    return false unless instrument = assign_instrument(person, song)

    assignments << OpenStruct.new(person: person, song: song, instrument: instrument)
    true
  end

  def print_assignments
    puts "#{name}:\n\n"
    assignments.group_by { |assignment| assignment.person.name }.each do |person_name, assignments|
      name_char_length = person_name.length + 2
      puts "#{person_name}: #{' ' * (13 - name_char_length)}#{assignments[0].song&.name}, #{assignments[0].instrument&.name}\n"
      puts "#{assignments[1].song&.name}, #{assignments[1].instrument&.name}".prepend(' ' * 13)
    end
    puts "\n"
  end

  private

  def assign_song person
    song = person.unplayed_songs(Song.all_unassigned&.shuffle).sample

    return false if song.nil?

    person.already_played_songs << song
    song.assigned = true
    song
  end

  def assign_instrument person, song
    unplayed_instruments = person.unplayed_and_not_own_instruments(@instruments) || person.unplayed_instruments(@instruments)
    unused_instruments = song.unused_instruments_by_person(@instruments)
    instrument = (unused_instruments & unplayed_instruments).sample

    if !instrument
      unused_instruments = song.unused_instruments(@instruments)
      instrument = (unused_instruments & unplayed_instruments).sample
    end

    return false if instrument.nil?

    person.already_played_instruments << instrument
    song.already_used_instruments << instrument
    @instruments.delete(instrument)
  end
end

dave = Person.new 'Dave', [Instrument.new('percussion')]
ben = Person.new 'Ben', [Instrument.new('guitar')]
cole = Person.new 'Cole', [Instrument.new('trumpet'), Instrument.new('muted trumpet'), Instrument.new('op-1')].shuffle
christopher = Person.new 'Christopher', [Instrument.new('pump organ'), Instrument.new('yamaha #1'), Instrument.new('yamaha #2')].shuffle
alec = Person.new 'Alec', [Instrument.new('bass clarinet'), Instrument.new('flute')].shuffle
kristin = Person.new 'Kristin', [Instrument.new('270 #1'), Instrument.new('270 #2')].shuffle

keys = %w(a b-flat b c c-sharp d d-sharp e f f-sharp g a-flat)
songs = keys.map do |name|
  Song.new name
end

statuses = []
schedules = []

puts 'start assignments'

until (
  statuses.length > 0 && statuses.flatten.all? { |result| result == true }
)
  Song.all.each(&:clear_instruments)
  Person.all.each(&:clear_songs_and_instruments)
  statuses = []
  schedules = []

  dave.already_played_songs = [songs[0], songs[2], songs[6], songs[8]]
  kristin.already_played_songs = [songs[0], songs[6], songs[9], songs[11]]
  christopher.already_played_songs = [songs[1], songs[4], songs[5], songs[10]]
  ben.already_played_songs = [songs[1], songs[3], songs[5], songs[7]]
  alec.already_played_songs = [songs[2], songs[4], songs[8], songs[10]]
  cole.already_played_songs = [songs[3], songs[7], songs[9], songs[11]]

  ['Week 1', 'Week 2', 'Week 3', 'Week 4'].each do |week|
    schedule = Schedule.new(week)
    statuses << Person.all.shuffle.map do |person|
      first_result = schedule.assign_for person
      second_result = schedule.assign_for person
      first_result && second_result
    end
    schedules << schedule
    Song.clear_all_assigned
  end
end

schedules.each(&:print_assignments)

exit
