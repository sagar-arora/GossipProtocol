defmodule GossipTest do
  use ExUnit.Case
  doctest Gossip

  test "list generate test" do
    assert Gossip.list_generate_helper([1,2,3],2) == [1,3]
  end

  test "list generate test2" do
    assert Gossip.list_generate_helper([1,2,3,4],4) == [1,2,3]
  end

  test "check_distance_range1" do
    assert Gossip.check_distance_range({0.1,0.1},{0.001, 0.0001}) == true
  end

  test "check_distance_range2" do
    assert Gossip.check_distance_range({0.1,0.9},{0.001, 0.0001}) == false 
  end
end
