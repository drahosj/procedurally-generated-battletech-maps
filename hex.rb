MAX_X = 15
MAX_Y = 17

MAX_LEVEL=3

require 'set'

class Hex
  attr_accessor :map
  attr_accessor :x
  attr_accessor :y
  attr_accessor :level
  attr_accessor :has_road
  attr_accessor :road_type
  attr_accessor :road_angle

  def odd?
    return x % 2 == 1? true : false
  end

  def even?
    return !odd?
  end

  def neighbors
    n = []


    n << map[x][y-1] if y > 1
    n << map[x][y+1] if y < MAX_Y

    n << map[x-1][y] if x > 1
    n << map[x+1][y] if x < MAX_X

    if odd? and y > 1
      n << map[x-1][y-1] if x > 1
      n << map[x+1][y-1] if x < MAX_X
    end

    if even? and y < MAX_Y
      n << map[x-1][y+1] if x > 1
      n << map[x+1][y+1] if x < MAX_X
    end

    return n
  end

  def in_direction n
    if n == 0
      return map[x][y-1]
    elsif n == 3
      return map[x][y+1]
    elsif n == 1
      return nil if x >= MAX_X
      if odd?
        return nil if y <= 1
        return map[x+1][y-1]
      else
        return map[x+1][y]
      end
    elsif n == 2
      return nil if x >= MAX_X
      if odd?
        return map[x+1][y]
      else
        return map[x+1][y+1]
      end
    elsif n == 4
      return nil if x <= 1
      if odd?
        return map[x-1][y]
      else
        return map[x-1][y+1]
      end
    elsif n == 5
      return nil if x <= 1
      if odd?
        return map[x-1][y-1]
      else
        return map[x-1][y]
      end
    end
  end

  def initialize map, x, y
    @map = map
    @x = x
    @y = y
    @level = 0
  end

  def name
    return "%02d%02d" % [x, y]
  end

  def to_s
    return name
  end

  def hilliness v=Set[]
    if v.include?(self)
      return 0
    end

    v.add(self)
    if level == 0
      return 1
    else
      return level + neighbors.map{|h|h.hilliness(v)}.sum
    end
  end

  def make_hill(target, rng)
    while (h = hilliness) < target
      #puts("Current hex: #{name}")
      #puts("Neighbors: #{neighbors.map(&:to_s)}")
      o = neighbors.select{|n| n.level < @level}

      n_levels = o.map(&:level)
      max_level = n_levels.max
      max_level = 0 if max_level.nil?

      n_within_1 = n_levels.count{|n| n >= @level - 1}

      self_weight = 10 * (n_within_1)
      self_weight += (MAX_LEVEL - @level) * 5

      max_neighbor = neighbors.map(&:level).max
      if (max_neighbor > @level)
        self_weight += 20
      end

      if level - max_level > 2
        self_weight = 0
      end
      #puts("Current level: #{level}")
      #puts("Current hilliness: #{h}")
      #puts("Self weight: #{self_weight}")
      #puts("Adjacent, lower hexes: #{o.map(&:name)}")

      if self_weight == 0 and o.empty?
        # puts "Somehow too high and also no lower neighbors"
        @level = @level + 1
      elsif rng.rand(100) < self_weight or o.empty?
        # puts("Choosing to raise self")
        @level = @level + 1
      else
        t = o.sample(random: rng)
        # puts("Choosing to raise #{t}")
        t.make_hill(target, rng)
      end
    end
  end
end

def simple_dump(map, filename)
  f = File.open(filename, "w")
  f.write('<?xml version="1.0" encoding="UTF-8"?>')
  f.write('<map xmlns="http://pqz.us/btmap">')
  f.write("\n")
  for x in 1..MAX_X
    for y in 1..MAX_Y
      h = map[x][y]
      f.write('<hex column="%d" row="%d"><level>%d</level>' % [h.x, h.y, h.level])
      if h.has_road
        if h.road_type < 0
          type = "left"
        elsif h.road_type > 0
          type = "right"
        else
          type = "straight"
        end
        f.write('<path orientation="%d">%s</path>' % [h.road_angle, type])
      end
      f.write("</hex>\n");
    end
  end
  f.write("</map>")
  f.close()
end

map = []
for x in 1..MAX_X
  map[x] = []
  for y in 1..MAX_Y
    map[x][y] = Hex.new(map, x, y)
  end
end

p map[2][2].name
p map[2][2].neighbors.map(&:name)

p map[5][6].name
p map[5][6].neighbors.map(&:name)

p map[3][1].neighbors.map(&:to_s)

h0202 = map[2][2]

arg = ARGV[0].to_i
if (arg == 0) 
  rng = Random.new()
else
  rng = Random.new(arg)
end

(rng.rand(5) + 15).times do 
  x = rng.rand(MAX_X) + 1
  y = rng.rand(MAX_Y) + 1

  hex = map[x][y]
  puts("Making hill at #{hex}")

  hex.make_hill(20 + rng.rand(40), rng)
end

if (rng.rand(2) == 0) 
  puts("This one will have a road")

  up = rng.rand(2) == 0 ? true : false
  y = map[1][1..MAX_Y].filter{|h|h.level == 0}.sample(random:rng).y

  x = 1
  while (x <= MAX_X)
    swap = [false, false, false, true].sample(random:rng)

    hex = map[x][y]

    if up
      if swap
        nd = 2
      else
        nd = 1
      end
    else
      if swap
        nd = 1
      else
        nd = 2
      end
    end


    nh = hex.in_direction(nd)
    if !nh.nil? and (nh.level - hex.level).abs > 1
      puts("In hex #{hex}")
      puts("Looking at hex #{nh}")
      puts("Trying direction #{nd} but it has level #{nh.level} curr #{hex.level}")
      puts("Swapping")
      swap = !swap
    end

    if up
      if swap
        nd = 2
      else
        nd = 1
      end
    else
      if swap
        nd = 1
      else
        nd = 2
      end
    end

    nh = hex.in_direction(nd)
    if !nh.nil? and (nh.level - hex.level).abs > 1
      puts("Direction #{nd} still has level #{nh.level} curr #{hex.level}")
      puts("ending road")
      break
    end


    if up
      road_angle = 1
      if !swap
        road_type = 0
        nh = hex.in_direction(1)
      else
        road_type = 1
        up = false
        nh = hex.in_direction(2)
      end
    else
      road_angle = 2
      if !swap
        road_type = 0
        nh = hex.in_direction(2)
      else road_type = -1
        up = true
        nh = hex.in_direction(1)
      end
    end
    hex.has_road = true
    hex.road_type = road_type
    hex.road_angle = road_angle

    if nh.nil?
      break
    else
      x += 1
      y = nh.y
    end
  end
end


simple_dump(map, "map.xml")
