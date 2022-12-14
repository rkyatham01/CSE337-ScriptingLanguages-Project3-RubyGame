class ValueError < RuntimeError
end

class Cave
  def initialize()
    @edges = [[1, 2], [2, 10], [10, 11], [11, 8], [8, 1], [1, 5], [2, 3], [9, 10], [20, 11], [7, 8], [5, 4],
                      [4, 3], [3, 12], [12, 9], [9, 19], [19, 20], [20, 17], [17, 7], [7, 6], [6, 5], [4, 14], [12, 13],
                      [18, 19], [16, 17], [15, 6], [14, 13], [13, 18], [18, 16], [16, 15], [15, 14]]
    # add cave attributes
    @rooms = Hash.new
    num = 1
    maxNum = 21

    while num < maxNum do
      @rooms[num] = Room.new(num)
      num += 1
      end
    
    @edges.each do |firstRoom, secondRoom|
      @rooms[firstRoom].connect(@rooms[secondRoom])
    end
  end

  def room(n)
    if n <= 0 || n > 20
      return nil
    else
      return @rooms[n]
    end
  end

  def random_room()
    num = rand(0..20)
    return @rooms[num]
  end

  def add_hazard(h, n)

    while n > 0 do
      randRoom = rand(1..20)
      theRoom = @rooms[randRoom]
      if n == 0
        return 
      end

      if theRoom.has?(h)
        next
      else
        theRoom.add(h)
        n -= 1
      end
      end
  end

  def room_with(hazard)
    num = 1
    maxNum = 21

    while num < maxNum do
      curRoom = @rooms[num]
      if curRoom.has?(hazard)
        return curRoom
      end
      num += 1
      end
    return nil
  end

  def move(hazard, frm, to)
    if frm.has?(hazard)
      frm.remove(hazard)
    else
      raise ValueError, "This would be a Value Error"
    end
    to.add(hazard)
  end

  def entrance()
    num = 1
    maxNum = 21

    while num < maxNum do
      curRoom = @rooms[num]
      if curRoom.safe?()
        return curRoom
      end
      num += 1
      end
    return nil
  
  end

end

class Player

  attr_reader :room
  # add specified Player methods
  def initialize()
    @senses = Hash.new
    @encounters = Hash.new
    @actions = Hash.new
    @room = nil
  end

  def sense(hazard, &callback)
    @senses[hazard] = callback    
  end

  def encounter(hazard, &callback)
    @encounters[hazard] = callback    
  end

  def action(act, &callback)
    @actions[act] = callback
  end

  def enter(room)
    @room = room

    if not @room.empty?()
      @encounters.each do |hazrd, func|
        if @room.has?(hazrd)
          func.call # call the function and break
          break
        end
      end
    end

  end

  def explore_room()
      @room.neighbors.each do |neiRoom|
        @senses.each do |hazrd, func|
          if neiRoom.has?(hazrd)
            func.call  
          end
        end
      end
  end

  def act(action, destination)
    actionFoundOrNot = 0
    
    @actions.each do |eachAct, func|
      if action == eachAct
        actionFoundOrNot = 1 # if its found
        func.call(destination) # we want the thing to go to this
        #destination after the call
      end
    end

    if actionFoundOrNot == 0
      raise KeyError, "This would produce a keyerror exception"
      #bc this means it did not find the action
    end
  end


end


class Room

  attr_reader :number
  attr_reader :hazards
  attr_reader :neighbors

  def initialize(number)
    @number = number
    @hazards = []
    @neighbors = []
  end

  # add specified Room methods
  def add(hazard)
    if (hazard.is_a?(String)) || (hazard.is_a?(Symbol))
      @hazards.append(hazard)
    else
      raise TypeError, "Not a String or Symbol"
    end
   
  end

  def has?(hazard)
    return @hazards.include? hazard
  end

  def remove(hazard)
    if has?(hazard)
      @hazards.delete(hazard)
    else
      raise ValueError, "Can't remove a non-existent hazard"
    end
  end

  def empty?()
    return @hazards.empty?
  end

  def safe?()
    
    @neighbors.each do |nei| 
      if !nei.empty?()
        return false
      end
    end
      
    if empty?()
      return true
    else
      return false
    end

  end

  def connect(other_room)
    @neighbors.push(other_room)
    other_room.neighbors.push(self)
  end

  def exits()
    arr = Array.new
    @neighbors.each do |x|
      arr.append(x.number)
    end
    return arr   
  end

  def neighbor(number)
    @neighbors.each do |x|
      if x.number == number
        return x
      end
    end
    return nil
  end

  def random_neighbor()

    arr2 = Array.new
    @neighbors.each do |x|
      arr2.append(x)
    end
    
    if arr2.empty?()
      raise IndexError, "Raises a Index Error"
    else
      randIndx = rand(0..arr2.length-1)
      puts randIndx
      return arr2.at(randIndx)
    end
  end
end

class Console
  def initialize(player, narrator)
    @player   = player
    @narrator = narrator
  end

  def show_room_description
    @narrator.say "-----------------------------------------"
    @narrator.say "You are in room #{@player.room.number}."

    @player.explore_room

    @narrator.say "Exits go to: #{@player.room.exits.join(', ')}"
  end

  def ask_player_to_act
    actions = {"m" => :move, "s" => :shoot, "i" => :inspect }

    accepting_player_input do |command, room_number|
      @player.act(actions[command], @player.room.neighbor(room_number))
    end
  end

  private

  def accepting_player_input
    @narrator.say "-----------------------------------------"
    command = @narrator.ask("What do you want to do? (m)ove or (s)hoot?")

    unless ["m","s"].include?(command)
      @narrator.say "INVALID ACTION! TRY AGAIN!"
      return
    end

    dest = @narrator.ask("Where?").to_i

    unless @player.room.exits.include?(dest)
      @narrator.say "THERE IS NO PATH TO THAT ROOM! TRY AGAIN!"
      return
    end

    yield(command, dest)
  end
end

class Narrator
  def say(message)
    $stdout.puts message
  end

  def ask(question)
    print "#{question} "
    $stdin.gets.chomp
  end

  def tell_story
    yield until finished?

    say "-----------------------------------------"
    describe_ending
  end

  def finish_story(message)
    @ending_message = message
  end

  def finished?
    !!@ending_message
  end

  def describe_ending
    say @ending_message
  end
end
