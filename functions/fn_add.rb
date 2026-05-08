# frozen_string_literal: true

class FnAdd
  def initialize(people)
    @people = people
  end

  def call
    loop do
      person = prompt_person
      break if person.nil?

      @people << person
      puts "Registered: #{person['name']} | #{person['gender']} | #{person['workspace']}"
      puts "Total people: #{@people.length}"

      break unless ask_continue?
    end
  end

  private

  def prompt_person
    print "  Name: "
    $stdout.flush
    name = gets&.chomp&.strip
    return nil if name.nil?

    if name.empty?
      puts "Error: Name cannot be empty. Please start over."
      return prompt_person
    end

    gender = prompt_gender
    return nil if gender.nil?

    print "  Workspace: "
    $stdout.flush
    workspace = gets&.chomp&.strip
    return nil if workspace.nil?

    if workspace.empty?
      puts "Error: Workspace cannot be empty. Please start over."
      return prompt_person
    end

    { 'name' => name, 'gender' => gender, 'workspace' => workspace.downcase }
  end

  def prompt_gender
    print "  Gender (m/f): "
    $stdout.flush
    raw = gets&.chomp&.strip
    return nil if raw.nil?

    case raw.downcase
    when 'm' then 'male'
    when 'f' then 'female'
    else
      puts "Error: Invalid gender '#{raw}'. Please enter 'm' (male) or 'f' (female)."
      prompt_gender
    end
  end

  def ask_continue?
    loop do
      print "  Add another person? (y/n): "
      $stdout.flush
      answer = gets&.chomp&.strip
      return false if answer.nil?

      case answer.downcase
      when 'y' then return true
      when 'n' then return false
      else
        puts "Error: Please enter 'y' or 'n'."
      end
    end
  end
end