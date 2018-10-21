defmodule ChordProtocol do
  use GenServer

  def main(number_of_peer, num_requests) do
    m = String.to_integer(number_of_peer)
    num_requests = String.to_integer(num_requests)
    IO.inspect(num_requests)
    nodes = Enum.map((1..m), fn(id) ->
      {:ok, id} = GenServer.start_link(__MODULE__, [m])
      id
    end)
    IO.inspect(nodes)
    build_chord_topology(nodes, m)
    query_chord(nodes, num_requests, m)
  end

  def query_chord(nodes, requests, m) do
    :random.seed(:erlang.now)
    Enum.each(nodes, fn(node)->
      Enum.each((1..requests), fn(i)->
        random_key = get_destination_key(get_random_hash(), m, nodes)
        IO.puts("adwedw")
        IO.inspect(random_key)
        single_query(node, random_key)
      end)
    end)
  end

  # def start_protocol(node, destination) do
  #   GenServer.callback()
  # end

  def single_query(node, key) do
    finger_table = get_finger_table(node)
    node_key = get_node_id(node)
    IO.inspect(finger_table)
    if node_key==key do
      IO.puts "Key Found"
    else
      Enum.each(finger_table, fn(node)->
          highest_successor = find_neighbour(node, finger_table)
          cond do
            highest_successor == nil ->
              recurse_ring(node, get_node_succesor(node), key)
            true ->
              recurse_ring(node, highest_successor, key)
        end
      end)
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
     next_cyclic_key = find_neighbour(key, nodes)
     next_cyclic_key
     IO.inspect(next_cyclic_key)
  end


  def build_chord_topology(nodes, m) do
    Enum.each(nodes, fn(node)->
      successor = find_successor(node, nodes)
      update_successor(node, successor)
      node_finger_table = populate_finger_table(get_node_id(node), m, nodes)
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
    finger_table_size = 1..m
    finger_table  = Enum.reduce(finger_table_size, [], fn i, table ->
      value = n + i |> rem(trunc(:math.pow(2, m)))
      table ++ [find_neighbour(value, all_nodes)]
    end)
    finger_table
  end

  def find_successor(process_id, nodes) do
    index = Enum.find_index(nodes, fn(x) -> x==process_id end)
    total_nodes = Enum.count(nodes)
    nextIndex = if index+1 < total_nodes do index+1 else 0 end
    successor = Enum.fetch(nodes, nextIndex)
    successor
  end

  def find_neighbour(value, all_nodes) do
    next = Enum.reduce(all_nodes, nil, fn node, pointer ->
        if get_node_id(node) < value do
          node
        else
          pointer
        end
    end)
    next
  end

  def get_node_id(process_id) do
    GenServer.call(process_id, {:getNodeId})
  end

  def get_finger_table(process_id) do
    GenServer.call(process_id, {:getFingerTable})
  end

  def get_node_succesor(process_id) do
    GenServer.call(process_id, {:getSuccesor})
  end

# Callbacks

  def handle_call({:updateSuccessor, successor_id}, _from, state) do
    {id, fingertable, _} = state
    state = {id, fingertable, successor_id}
    {:reply, id, state}
  end

  def handle_call({:updateFingerTable, table}, _from, state) do
    {id, _, next} = state
    state = {id, table, next}
    {:reply, id, state}
  end

  def handle_call({:getNodeId}, _from, state) do
    {id, _,_} = state
    {:reply, id, state}
  end

  def handle_call({:getFingerTable}, _from, state) do
    {_, _, finger_table} = state
    {:reply, finger_table, state}
  end

  def handle_call({:getSuccessor}, _from, state) do
    {_, successor, _} = state
    {:reply, successor, state}
  end

  def handle_cast({:recurseRing, successor, key}, state) do
    single_query(successor, key)
    {:noreply, state}
  end

  def init([m]) do
    # IO.inspect(self)
    node_id = :crypto.hash(:sha, Float.to_string(:rand.uniform)) |> Base.encode16
    IO.inspect(node_id)
    {node_id, _} = Integer.parse(node_id, 16)
    node_id = rem(node_id, trunc(:math.pow(2, m)))
    IO.inspect(node_id)
    {:ok, {node_id, nil, []}}
  end
end
