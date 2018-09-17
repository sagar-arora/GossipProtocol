defmodule Gossip do
  @moduledoc """
  Documentation for Gossip.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Gossip.hello()
      :world

  """
  def main(args) do
    case args do
      [numNodes, "full", "gossip"] ->

    end
  end

  def generate_full_nodes_topology(numNodes) do
    Enum.each(1..numNodes,
  end
end
defmodule GossipProtocol do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, {false, []})
  end

  ## TODO: add neighbors based on the topology
  def add_neighbours(process_id, neighbors_list) do
    GenServer.cast(process_id, {:add_neighbors, neighbors_list})
  end

  ## TODO: each actor on its end run the GossipProtocol
  def start_gossip_protocol()  do
    GenServer.cast(process_id, {:start_gossip})
  end

  # Server @callback function_name() :: type
    def init(state) do
      {:ok, state}
    end

    def handle_cast({:add_neighbors, neighbors_list}, state) do
      {bool , initial_neighbors_list} -> state
      new_state = {bool, initial_neighbors_list | neighbors_list}
      {:no_reply, new_state}
    end

    def handle_cast({:start_gossip}, state) do

    end
end
