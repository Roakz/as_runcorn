require 'pp'
require 'securerandom'


class DAG
  Node = Struct.new(:id, :parents, :children, :subgraph_id, :ancestors, :descendants)

  def initialize
    @nodes = {}
  end

  def add_node(node_id)
    @nodes[node_id] ||= Node.new(node_id, [], [], SecureRandom.hex, nil, nil)
  end

  def add_edge(parent:, child:)
    add_node(parent)
    add_node(child)

    @nodes[parent].children << child
    @nodes[child].parents << parent

    # child's subgraph_id replaced with parent's subgraph_id where it appears
    parent_node = @nodes[parent]
    child_node = @nodes[child]
    @nodes.values.each do |node|
      if node.subgraph_id == child_node.subgraph_id
        node.subgraph_id = parent_node.subgraph_id
      end
    end
  end

  def ancestors
    @nodes.values.each do |node|
      node.ancestors = nil
    end

    @nodes.values.each {|node| calculate_ancestors!(node)}

    @nodes.values.flat_map {|node|
      node.ancestors.flat_map {|ancestor|
        {ancestor: ancestor, node: node.id, subgraph_id: node.subgraph_id}
      }.flatten(1)
    }
  end

  def descendants
    @nodes.values.each do |node|
      node.descendants = nil
    end

    @nodes.values.each {|node| calculate_descendants!(node)}

    @nodes.values.flat_map {|node|
      node.descendants.flat_map {|descendant|
        {descendant: descendant, node: node.id, subgraph_id: node.subgraph_id}
      }
    }
  end


  private

  def calculate_ancestors!(node)
    return unless node.ancestors.nil?

    node.ancestors = []
    node.parents.each do |p|
      calculate_ancestors!(@nodes[p])
      node.ancestors.concat(@nodes[p].ancestors)
    end

    node.ancestors.concat(node.parents)
    node.ancestors << node.id
    node.ancestors.uniq!
  end

  def calculate_descendants!(node)
    return unless node.descendants.nil?

    node.descendants = []
    node.children.each do |c|
      calculate_descendants!(@nodes[c])
      node.descendants.concat(@nodes[c].descendants)
    end

    node.descendants.concat(node.children)
    node.descendants << node.id
    node.descendants.uniq!
  end

end
