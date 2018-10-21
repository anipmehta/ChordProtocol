defmodule ChordProtocol do
  use GenServer

  def main(number_of_nodes, num_requests) do
    M = 5
    nodes = Enum.map((1..M), fn() ->
      {:ok, id} = GenServer.start_link(__MODULE__, [])
      id
    end)

    IO.inspect(nodes)
  end

  def update_successor(process_id, successor_id) do
    GenServer.call(process_id, {:updateSuccessor, successor_id})
  end

  def upadate_finger_table(process_id, table) do
    GenServer.call(process_id, {:updateFingerTable})
  end

  def populate_finger_table(n, m, all_nodes) do
    finger_table_size = 1..m
    finger_table  = Enum.reduce(finger_table_size, [], fn i, table ->
      value = n + i |> rem(:math.pow(2, m))
      table ++ find_neighbour(value, all_nodes)
    end)
    finger_table
  end

  def find_successor(process_id, nodes) do
    index = Enum.fetch(nodes, process_id)
    total_nodes = Enum.count(nodes)
    nextIndex = if index+1 < total_nodes do index+1 else 0
    successor = Enum.fetch(nodes, nextIndex)
    successor 
  end
  def find_neighbour(value, all_nodes) do
    next = Enum.reduce(all_nodes, nil, fn nodes, pointer ->
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

# Callbacks

  def handle_call({:updateSuccessor, successor_id}, _from, state) do
    {id, fingertable, next} = state
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

  def init([]) do
    node_id = :crypto.hash(:sha, self()) |> Base.encode16
    {:ok, {node_id, nil, []}}
  end
end
