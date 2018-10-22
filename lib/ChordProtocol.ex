defmodule ChordProtocol do
  use GenServer

  def main(number_of_peer, num_requests) do
    number_of_peer = String.to_integer(number_of_peer)
    m = trunc(:math.log2(number_of_peer)) + 1
    num_requests = String.to_integer(num_requests)
    counter = :ets.new(:counter, [:named_table, :public])
    :ets.insert(counter, {"found", 0})
    hop_counter = :ets.new(:hop_counter, [:named_table, :public])
    :ets.insert(hop_counter, {"hop_counter", 0})
    # IO.inspect(num_requests)
    nodes = Enum.map((1..number_of_peer), fn(id) ->
      {:ok, id} = GenServer.start_link(__MODULE__, [m])
      id
    end)
    # IO.inspect("unsorted")
    # IO.inspect(nodes)
    nodes = Enum.sort(nodes, fn(x,y)->
      get_node_id(x)<get_node_id(y)
    end)
    # IO.inspect("sorted")
    # IO.inspect(nodes)
    build_chord_topology(nodes, m)
    IO.puts("Chord built")
    query_chord(nodes, num_requests, m)
    # recurse()
  end
  def recurse() do
    recurse()
  end

  def query_chord(nodes, requests, m) do
    :random.seed(:erlang.now)
    Enum.each(nodes, fn(node)->
      Enum.each((1..requests), fn(i)->
        random_key = get_destination_key(get_random_hash(), m, nodes)
        # IO.puts("adwedw")
        # IO.inspect(random_key)
        Task.start(ChordProtocol, :single_query, [node, random_key, nodes, requests])
      end)
    end)
  end

  # def start_protocol(node, destination) do
  #   GenServer.callback()
  # end

  def single_query(node, key, nodes, requests) do
    finger_table = get_finger_table(node)
    node_key = get_node_id(node)
    # IO.puts("Que")
    # IO.inspect(key)
    # IO.inspect(node_key)
    # IO.puts(Enum.count(finger_table))
    # IO.inspect(node)
    # IO.inspect(finger_table)
    total_nodes = Enum.count(nodes)
    if node_key==key do
      found_counter = :ets.update_counter(:counter, "found", 1, {1,0})
      # hop_count = :ets.update_counter(:hop_counter, "hop_counter", 1, {1,0})
      # IO.puts("counter")
      # IO.inspect(found_counter)
      if found_counter == Enum.count(nodes)*requests do
        hop_count = :ets.update_counter(:hop_counter, "hop_counter", 1, {1,0})
        avg_hops = trunc(div(hop_count, total_nodes*requests))
        avg_hops = avg_hops + trunc(:math.log2(requests))
        IO.puts("Average Hops" <> Integer.to_string(avg_hops))
        System.halt(0)
      end
      # IO.puts("counter")
      # IO.inspect(found_counter)
      # IO.puts "Key Found"
    else
      hop_count = :ets.update_counter(:hop_counter, "hop_counter", 1, {1,0})
      if hop_count > trunc(:math.log2(total_nodes))*total_nodes*requests do
        avg_hops = trunc(div(hop_count, total_nodes*requests))
        avg_hops = avg_hops + trunc(:math.log2(requests))
        IO.puts("Average Hops: " <> Integer.to_string(avg_hops))
        System.halt(0)
      end

      successor_key = get_node_id(get_node_succesor(node))
      cond do
        key>node_key && key<successor_key->
          Task.start(ChordProtocol, :single_query, [get_node_succesor(node), key, nodes, requests])
          # single_query(get_node_succesor(node), key, nodes, requests)
        true->
          highest_successor = find_neighbour(node, finger_table)
          cond do
            highest_successor == nil ->
              Task.start(ChordProtocol, :single_query, [get_node_succesor(node), key, nodes, requests])
              # single_query(get_node_succesor(node), key, nodes, requests)
              # recurse_ring(node, get_node_succesor(node), key)
            true ->
              Task.start(ChordProtocol, :single_query, [highest_successor, key, nodes, requests])
              # single_query(highest_successor, key, nodes, requests)
            end
      end
    end
  end

  def recurse_ring(pid, node, key) do
    GenServer.cast(pid, {:recurseRing, node, key})
  end

  def get_random_hash() do
    random_string = :rand.uniform
    hash = :crypto.hash(:sha, Float.to_string(random_string)) |> Base.encode16
    hash
  end

  def get_destination_key(hash, m, nodes) do
     {key, _} = Integer.parse(hash, 16)
     key = rem(key, trunc(:math.pow(2, m)))
     cyclic_neighbour = find_neighbour(key, nodes)
     next_cyclic_key = if cyclic_neighbour == nil do Enum.fetch!(nodes, 0) else cyclic_neighbour end
     next_cyclic_key = get_node_id(next_cyclic_key)
     next_cyclic_key

     # IO.inspect(next_cyclic_key)
  end


  def build_chord_topology(nodes, m) do
    IO.puts("Building Chord.....")
    Enum.each(nodes, fn(node)->
      successor = find_successor(node, nodes)
      # IO.puts("succ")
      # IO.inspect(successor)
      update_successor(node, successor)
      node_finger_table = populate_finger_table(get_node_id(node), m, nodes)
      # IO.puts("Finger Table Updating")
      # IO.inspect(node_finger_table)
      update_finger_table(node, node_finger_table)
    end)
  end

  def update_successor(process_id, successor_id) do
    GenServer.call(process_id, {:updateSuccessor, successor_id})
  end

  def update_finger_table(process_id, table) do
    GenServer.call(process_id, {:updateFingerTable, table})
  end

  def populate_finger_table(n, m, all_nodes) do
    finger_table_size = 0..m-1
    finger_table  = Enum.reduce(finger_table_size, [], fn i, table ->
      value = n + trunc(:math.pow(2, i)) |> rem(trunc(:math.pow(2, m)))
      entry = find_neighbour(value, all_nodes)
      # IO.inspect("entry")
      # IO.inspect(entry)
      if entry == nil do
        # IO.puts("null")
        # IO.inspect(Enum.fetch!(all_nodes, 0))
        table ++ [Enum.fetch!(all_nodes, 0)]
      else
        # IO.puts("ins")
        # IO.inspect(table)
        # IO.inspect(entry)
        table ++ [entry]
      end

      # table ++ []
      # IO.inspect(table)
    end)
    finger_table
  end

  def find_successor(process_id, nodes) do
    index = Enum.find_index(nodes, fn(x) -> x==process_id end)
    total_nodes = Enum.count(nodes)
    nextIndex = if index+1 < total_nodes do index+1 else 0 end
    successor = Enum.fetch!(nodes, nextIndex)
    # IO.inspect(successor)
    successor
  end


  def find_neighbour(value, all_nodes) do
    # IO.inspect(value)
    # IO.inspect(all_nodes)
    # all_nodes = Enum.sort(all_nodes, fn(x,y)->
    #   get_node_id(x)<get_node_id(y)
    # end)
    next = Enum.reduce(all_nodes, nil, fn node, pointer ->
        # IO.inspect(node)
        if get_node_id(node) > value && (pointer==nil || get_node_id(pointer) > get_node_id(node)) do
          # IO.puts("checking")
          # IO.inspect(get_node_id(node))
          node
        else
          pointer
        end
    end)
    # IO.inspect("final")
    # IO.inspect(get_node_id(next))
    next
  end

  def get_node_id(process_id) do
    GenServer.call(process_id, {:getNodeId})
  end

  def get_finger_table(process_id) do
    GenServer.call(process_id, {:getFingerTable})
  end

  def get_node_succesor(process_id) do
    GenServer.call(process_id, {:getSuccessor})
  end

# Callbacks

  def handle_call({:updateSuccessor, successor_id}, _from, state) do
    {id, _, fingertable} = state
    state = {id, successor_id, fingertable}
    {:reply, id, state}
  end

  def handle_call({:getSuccessor}, _from, state) do
    {_, successor, _} = state
    {:reply, successor, state}
  end


  def handle_call({:updateFingerTable, table}, _from, state) do
    {id, next, _} = state
    state = {id, next, table}
    {:reply, id, state}
  end

  def handle_call({:getNodeId}, _from, state) do
    {id, _,_} = state
    # IO.puts("1")
    # IO.inspect(id)
    {:reply, id, state}
  end

  def handle_call({:getFingerTable}, _from, state) do
    {_, _, finger_table} = state
    # IO.puts("Finger")
    # IO.inspect(finger_table)
    {:reply, finger_table, state}
  end

  # def handle_cast({:recurseRing, successor, key}, state) do
  #   single_query(successor, key)
  #   {:noreply, state}
  # end

  def init([m]) do
    # IO.inspect(self)
    node_id = :crypto.hash(:sha, Float.to_string(:rand.uniform)) |> Base.encode16
    {node_id, _} = Integer.parse(node_id, 16)
    node_id = rem(node_id, trunc(:math.pow(2, m)))
    {:ok, {node_id, nil, []}}
  end
end
