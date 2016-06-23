module FluentPath

  @@reserved = ['all','not','empty','exists','where','select','extension','startsWith','contains','in','distinct','=','!=','<=','>=','<','>','and','or','xor']

  def self.parse(expression)
    build_tree( tokenize(expression) )
  end

  # This method tokenizes the expression into a flat array of tokens
  def self.tokenize(expression)
    raw_tokens = expression.gsub('()','').split /(\(|\)|\s)/
    tokens = []
    raw_tokens.each do |token|
      if token.include?('.') && !(token.start_with?('\'') && token.end_with?('\''))
        token.split('.').each{|t|tokens << t}
      elsif token.include?('|')
        array = []
        token.split('|').each{|t|array << t.gsub('\'','')}
        tokens << array
      else
        tokens << token
      end
    end
    tokens.delete_if { |token| (token.length==0 || (token =~ /\s/)) }
    puts "TOKENS: #{tokens}"
    tokens
  end

  # This method builds an Abstract Syntax Tree (AST) from a flat list of tokens
  def self.build_tree(tokens)
    return if tokens.empty?
    tree = []
    while tokens.length > 0
      token = tokens.delete_at(0)
      if '(' == token # sub expression
        tree << FluentPath::Expression.new(build_tree(tokens))
      elsif ')' == token
        return tree
      elsif '.' != token
        tree << atom(token)
      end
    end
    # post-processing
    tree.each_with_index do |token,index|
      if token==:extension # 'extension' can be a path or a function call (if followed by a block)
        next_token = tree[index+1]
        tree[index] = 'extension' if next_token.nil? || !next_token.is_a?(FluentPath::Expression)
      end
    end
    tree
  end

  # This method converts a token within an expression to a native number (if applicable)
  # otherwise it considers it to be a symbol.
  def self.atom(token)
    # check if it is a number
    value = token
    begin
      value = Float(token)
    rescue
      value = token
      value = token.to_sym if @@reserved.include?(token)
      value = true if token=='true'
      value = false if token=='false'
    end      
    value
  end

end