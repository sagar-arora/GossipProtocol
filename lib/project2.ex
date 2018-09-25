defmodule Gossip do
  @moduledoc """
  Documentation for Gossip.
  """
  def main(args) do
    case args do
      [numNodes, "full", "gossip"] ->
        nodes_topology_map = generate_full_nodes_topology(numNodes, :gossip)
        Enum.each(nodes_topology_map, fn {x,y} ->
                                      GossipProtocol.add_neighbours(x,y) end)
        # Pick a random node and tell them gossip
        {x,y} = Enum.random(nodes_topology_map)
        IO.puts("#{inspect(x)} knows the GOSSIP")
        GossipProtocol.tell_gossip(x)
        Enum.each(nodes_topology_map, fn {x,y} ->
                                      GossipProtocol.start_gossip_protocol(x)
                                      end)
        #receiver()
        [numNodes, "full", "pushsum"] ->
          start_time = :erlang.system_time / 1.0e6 |> round
          nodes_topology_map = generate_full_nodes_topology(numNodes, :pushsum)
          Enum.each(nodes_topology_map, fn {x,y} ->
                                        PushSum.add_neighbours(x,y) end)
          # Pick a random node and tell them gossip
          {x,y} = Enum.random(nodes_topology_map)
          #IO.puts("#{inspect(x)} knows the GOSSIP")
          PushSum.start_push_sum(x)


       [numNodes, "rand2D", "gossip"] ->
        nodes_topology_map = generate_rand2D_topology(numNodes,:gossip)
        #IO.puts("printing map #{nodes_topology_map}")
        Enum.each(nodes_topology_map, fn {x, y} ->
                                        GossipProtocol.add_neighbours(x,y) end)
        # Pick a random node and tell them gossip
        {x,y} = Enum.random(nodes_topology_map)
        IO.puts("#{inspect(x)} knows the GOSSIP")
        GossipProtocol.tell_gossip(x)
        Enum.each(nodes_topology_map, fn {x,y} ->
                                      GossipProtocol.start_gossip_protocol(x)
                                      end)
      [numNodes, "rand2D", "pushsum"] ->
        nodes_topology_map = generate_rand2D_topology(numNodes,:pushsum)
                                       #IO.puts("printing map #{nodes_topology_map}")
        Enum.each(nodes_topology_map, fn {x, y} -> GossipProtocol.add_neighbours(x,y) end)
                                       # Pick a random node and tell them gossip
        {x,y} = Enum.random(nodes_topology_map)
        PushSum.start_push_sum(x)
       [numNodes, "line", "gossip"] ->
         nodes_topology_map = generate_line_topology(numNodes, :gossip)
         IO.puts("printing map #{inspect nodes_topology_map}")
         Enum.each(nodes_topology_map, fn {x, y} ->
                                         GossipProtocol.add_neighbours(x,y) end)
         # Pick a random node and tell them gossip
         {x,y} = Enum.random(nodes_topology_map)
         IO.puts("#{inspect(x)} knows the GOSSIP")
         GossipProtocol.tell_gossip(x)
         Enum.each(nodes_topology_map, fn {x,y} ->
                                       GossipProtocol.start_gossip_protocol(x)
                                       end)
                                       [numNodes, "line", "pushsum"] ->
                                         #start_time = :erlang.system_time / 1.0e6 |> round
                                         nodes_topology_map = generate_line_topology(numNodes, :pushsum)
                                         Enum.each(nodes_topology_map, fn {x,y} ->
                                                                       PushSum.add_neighbours(x,y) end)
                                         # Pick a random node and tell them gossip
                                         {x,y} = Enum.random(nodes_topology_map)
                                         #IO.puts("#{inspect(x)} knows the GOSSIP")
                                         PushSum.start_push_sum(x)

    end


  end

  def receiver() do
    receive do
      {:finished, pid} -> GossipProtocol.stop(pid)
    end
  end

  def generate_full_nodes_topology(numNodes, protocol) do
    ok_nodes_tuples_list = create_server_list(numNodes, protocol)
    nodes_list = Enum.map(ok_nodes_tuples_list, fn ({x,y}) -> y end)
    IO.puts(inspect(nodes_list))

    map = Enum.reduce(nodes_list, %{},
                    fn (x, acc) -> Map.put(acc, x, list_generate_helper(nodes_list, x))
                    end
                    )
  end

  def create_server_list(numNodes, :gossip) do
    nodes_list = Enum.map(1..numNodes, fn x -> GossipProtocol.start_link(numNodes, self())
                          end
                          )
    nodes_list
  end

  def create_server_list(numNodes, :pushsum) do
    nodes_list = Enum.map(1..numNodes,
                          fn x -> PushSum.start_link(numNodes, x, self())
                          end
                          )
    nodes_list
  end


  def generate_rand2D_topology(numNodes, protocol) do
    process_ok_tuples_list = create_server_list(numNodes, protocol)
    nodes_list = Enum.map(process_ok_tuples_list, fn ({x,y}) -> y end)
    IO.puts(inspect(nodes_list))
    generate_x_y = Enum.reduce(nodes_list, %{},
                            fn (x, acc) -> Map.put(acc, x,
                             {:rand.uniform(10)/10, :rand.uniform(10)/10})
                            end
                              )
  succeding_pid_list =  Enum.map(nodes_list, fn x ->
                                  {x , list_generate_helper(nodes_list, x)}
                                  end
                                )
    IO.puts(inspect(succeding_pid_list))
    map = Enum.reduce(succeding_pid_list , %{},
                                  fn ({x, succeding_pid_list_of_x}, acc) ->
                                    IO.puts("pid= #{inspect(x)} and {x,y} = #{inspect(Map.get(generate_x_y, x))}")
                                    new_list = Enum.filter(succeding_pid_list_of_x,
                                              fn (y) ->
                                              #  { _ , point1} = Map.fetch(generate_x_y, x)
                                              #  { _ , point2} = Map.fetch(generate_x_y, y)
                                                check_distance_range(
                                                  Map.get(generate_x_y, x),
                                                  Map.get(generate_x_y, y)
                                                  )
                                              end
                                            )
                                    Map.put(acc, x, new_list)
                                  end
                    )
   map
  end

 ## check if the distance between point is in the range 0.1
  def check_distance_range({x1, y1}, {x2, y2}) do
    import :math
    sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)) <= 0.1
  end


## Gives all the succeding values from the list for the given element
## For ex. succeding_elements([1,2,3,4], 1) returns a list [2,3,4]
## Check Test cases for more Examples
  def succeding_elements([head|tail], element) do
    if(head == element) do
      tail
    else
      succeding_elements(tail, element)
    end
  end

  def succeding_elements([], element) do
    []
  end

  def list_generate_helper([], element) do
    []
  end

  def list_generate_helper([head | tail], element) do
      if(head == element) do
        list_generate_helper(tail, element)
      else
        [head | list_generate_helper(tail, element)]
      end
  end


def generate_3D_grid_nodes_topology(numNodes) do


end

# Line Topology
# Processes should be arranged in a straight line
def generate_line_topology(numNodes, protocol) do
  process_ok_tuples_list = create_server_list(numNodes, protocol)
  nodes_list = Enum.map(process_ok_tuples_list, fn ({x,y}) -> y end)

  if numNodes == 2 do
    [first_pid | second_pid] = nodes_list
    map = %{}
    map = Map.put(map, first_pid, [second_pid])
    map = Map.put(map, second_pid, [first_pid])
    map
  else
    map = Enum.reduce(nodes_list, %{}, fn (x, acc) ->
                                  Map.put(acc,
                                  x ,
                                  Enum.concat(get_element_before(nodes_list, x) , get_element_after(nodes_list, x))
                                  )
                                end)
    map

  end
end

## Imperfect line: Line arrangement but one random other neighboor is
## selected from the list of all actors
def generate_imperfect_line_topology(numNodes, protocol) do
  process_ok_tuples_list = create_server_list(numNodes, protocol)
  nodes_list = Enum.map(process_ok_tuples_list, fn ({x,y}) -> y end)

  if numNodes == 2 do
    [first_pid | second_pid] = nodes_list
    map = %{}
    map = Map.put(map, first_pid, [second_pid])
    map = Map.put(map, second_pid, [first_pid])
    map
  else
    map = Enum.reduce(nodes_list, %{}, fn (x, acc) ->
                                  Map.put( acc, x,
                                  Enum.concat( [Enum.random(nodes_list)],
                                  Enum.concat(get_element_before(nodes_list, x),
                                  get_element_after(nodes_list, x))
                                  )
                                )
                                end)
    map
  end
end

  def get_element_before([element| tail], element) do
    []
  end


def get_element_before([head | tail], element) do
    [head1 | tail1] = tail
    if head1 == element do
      [head]
    else
      get_element_before(tail, element)
    end
end


  def get_element_after([element | []], element) do
    []
  end
  def get_element_after([head | tail], element) do
    [head1 | tail1] = tail
    if head == element do
      [head1]
    else
      get_element_after(tail, element)
    end
  end

end

defmodule GossipProtocol do
  use GenServer

  def start_link(numNodes, parent_id) do
    import :math
    {numRound, _} = Integer.parse(Float.to_string((log2(numNodes))))
    GenServer.start_link(__MODULE__, {false, [], numRound, parent_id})
  end

  ## add neighbors based on the topology
  def add_neighbours(process_id, neighbors_list) do
    GenServer.cast(process_id, {:add_neighbors, neighbors_list})
  end

  ## Each actor on its end run the GossipProtocol
  def start_gossip_protocol(process_id)  do
    GenServer.cast(process_id, {:start_gossip})
  end

  def tell_gossip(process_id) do
    GenServer.cast(process_id, {:tell_gossip})
  end
  # Server @callback function_name() :: type
    def init(state) do
      IO.puts(inspect(state))
      {:ok, state}
    end


    def handle_cast({:add_neighbors, neighbors_list}, state) do
      {bool , initial_neighbors_list, numRound, parent_id} = state
      new_state = {bool, Enum.concat(initial_neighbors_list , neighbors_list), numRound, parent_id}
      {:noreply, new_state}
    end

    def handle_cast({:tell_gossip}, state) do
      {bool , initial_neighbors_list, numRound, parent_id} = state
      new_state = {true, initial_neighbors_list, numRound, parent_id}
      {:noreply, new_state}
    end

    def handle_cast({:start_gossip}, state) do
      {knows_gossip , neighbors_list, numRound, parent_id} = state
      # if bool is true that is the node knows the gossip and can start spreading gossip
      if knows_gossip == true do
        #random_number = :rand.uniform(length(neighbors_list))
        random_neighbour = Enum.random(neighbors_list)
        IO.puts("#{inspect(random_neighbour)} chosen by #{inspect(self())} ")
        send(random_neighbour, {:send_gossip_to_neighbor})
        start_gossip_protocol(self())
      # else wait for the gossip to come
      end
        start_gossip_protocol(self())
        {:noreply, state}
    end

      def handle_info({:send_gossip_to_neighbor}, state) do
      {bool, initial_neighbors_list, numRound, parent_id} = state
      if numRound == 0 do
        #IO.puts("")
        IO.puts("stop the process #{inspect(self())} and state during ending #{inspect(state)}")
        Process.exit(self(), :finished)
        #GossipProtocol.stop()
        #terminate(:finished, state)
        #stop(self(), :normal, :infinity) #reason \\ :normal, timeout \\ :infinity)
        #{:stop, :shutdown, state}
          #stop(server)
        #send(parent_id, {:finished, self()})
      end
      new_state = {true, initial_neighbors_list, numRound-1, parent_id}
      {:noreply, new_state}
    end

    def stop(pid) do
      GenServer.cast(pid, :stop)
    end

    def handle_cast(:stop, status) do
      {:stop, :normal, status}
    end

    def terminate(reason, _status) do
      IO.puts "Asked to stop because #{inspect reason}"
      :ok
    end
end

defmodule PushSum do
  use GenServer
  @accuracy :math.pow(10, -10)

  def start_link(numNodes, initial_sum_val, parent_id) do
    import :math
    #{numRound, _} = Integer.parse(Float.to_string((log2(numNodes))))
    initial_weight_val = 1
    numRound = 0
    GenServer.start_link(__MODULE__, {{initial_sum_val, initial_weight_val}, [], numRound, parent_id})
  end

  def init(state) do
    #IO.puts(inspect(state))
    {:ok, state}
  end

  def get_sum_weight_tuple(pid) do
    GenServer.call(pid, {:get_sum_weight_tuple})
  end

  ## add neighbors based on the topology
  def add_neighbours(process_id, neighbors_list) do
    GenServer.cast(process_id, {:add_neighbors, neighbors_list})
  end

  def handle_cast({:add_neighbors, neighbors_list}, state) do
    {bool , initial_neighbors_list, numRound, parent_id} = state
    new_state = {bool, Enum.concat(initial_neighbors_list , neighbors_list), numRound, parent_id}
    {:noreply, new_state}
  end

  def start_push_sum(pid) do
    GenServer.cast(pid, {:start_push_sum})
  end

  def handle_cast({:get_sum_weight_tuple}, _from, state) do
    {sum_weight_tuple , initial_neighbors_list, numRound, parent_id} = state
    {:reply, state}
  end

  def handle_cast({:start_push_sum}, state) do
    {{sum, weight} , neighbors_list, numRound, parent_id} = state
    random_neighbour = Enum.random(neighbors_list)
    half_sum = sum/2
    half_weight = weight/2
    send(random_neighbour, {:send_sum_weight_tuple, {half_sum, half_weight}})
    new_state = {{half_sum , half_weight} , neighbors_list, numRound, parent_id}
    {:noreply, new_state}
  end

  def handle_info( {:send_sum_weight_tuple, {half_sum, half_weight}}, state) do
    {{sum , weight} , initial_neighbors_list, numRound, parent_id} = state
    new_sum = sum + half_sum
    new_weight = weight + half_weight
    old_ratio = sum / weight
    new_ratio = new_sum / new_weight
    diff = (old_ratio - new_ratio)*(old_ratio - new_ratio) |> :math.sqrt
    if( diff < @accuracy) do
      IO.puts("The PathSum converged on the avg #{new_ratio}")
      Process.exit(self(), :finished)
    end
    new_state = {{new_sum , new_weight} , initial_neighbors_list, numRound, parent_id}
    start_push_sum(self())
    {:noreply, new_state}
  end

end
