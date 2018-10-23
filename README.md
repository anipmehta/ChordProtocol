# Project 3

**Implementation of Chord Protocol**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `proj3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:proj3, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/proj3](https://hexdocs.pm/proj3).

# Group Info
 - Anip Mehta  UFID : 96505636
 - Aniket Sinha UFID : 69598035
 
 # Implementation of Chord Protocol
 
 What is working?
 
 Creation of Chord topology from the given number of nodes and getting the peers(nodes) to perform the given number of requests. Finally,  the average number of hops(node connections) that have to be traversed to deliver a message gets displayed as the output.
 
 Following are the results from some sample runs:
  
```
Number of Peers 	   Number of Requests      Average number of Hops   	   
--------------------------------------------------------------------
8                           2                         3          
8                           3                         3           
8                           4                         5            
100                         3                         7            
100                         5                         8           
100                         10                        9           
500                         3                         9           
500                         10                        11           
500                         50                        13           
1024                        3                         11
1024                        5                         12 
1024                        10                        13 
```

Keeping the number of requests constant(=3),the graph of average number of hops to the number of peers was plotted.

```
Number of Peers 	   Number of Requests      Average number of Hops   	   
--------------------------------------------------------------------
8                           3                        4         
50                          3                        6          
100                         3                        7           
200                         3                        8           
500                         3                        9  
700                         3                        10 
1024                        3                        11
2024                        3                        12
```
It can be observed that the graph is logarithmic:

![graph](https://user-images.githubusercontent.com/4914264/47330096-0634a100-d645-11e8-87f1-caffdf8b36e3.png)

What is the largest network you managed to deal with?

The largest network we managed to deal with consisted of 5000 nodes. Beyond that, it was taking too much time to build the chord topology and update the finger table.

## Input

Syntax:
 - mix run proj3.ex (number of nodes) (number of requests)
 
 Example:
 - ``mix run proj3.ex 100 5``

## Output
 - Avrage number of hops to be traversed to deliver a message
 
