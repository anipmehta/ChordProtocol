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

 
