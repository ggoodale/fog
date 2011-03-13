Shindo.tests('Bluebox::Compute | block requests', ['bluebox']) do

  @block_format = {
    'cpu'             => Float,
    'description'     => String,
    'hostname'        => String,
    'id'              => String,
    'ips'             => [{'address' => String}],
    'memory'          => Integer,
    'product'         => Bluebox::Compute::Formats::PRODUCT,
    'status'          => String,
    'storage'         => Integer,
    'template'        => String,
    'lb_applications' => Array,
    'lb_options'      => {'weight' => Integer, 'port' => Integer, 'backup' => String}
  }

  tests('success') do

    @product_id      = '94fd37a7-2606-47f7-84d5-9000deda52ae' # 1 GB
    @template_id     = 'a00baa8f-b5d0-4815-8238-b471c4c4bf72' # Ubuntu 9.10 64bit
    @password        = 'chunkybacon'
    @lb_applications = []
    @lb_options      = {'weight' => 1, 'port' => 80, 'backup' => 'true'}

    @block_id = nil
    @lb_block_id = nil

    tests("create_block('#{@product_id}', '#{@template_id}', 'password' => '#{@password}')").formats(@block_format) do
      pending if Fog.mocking?
      data = Bluebox[:compute].create_block(@product_id, @template_id, 'password' => @password).body
      @block_id = data['id']
      data
    end

    tests("create_block('#{@product_id}', '#{@template_id}', 'password' => '#{@password}', 'lb_applications' => '#{@lb_applications.inspect}'), 'lb_options' => #{@lb_options.inspect}").formats(@block_format) do
      pending if Fog.mocking?
      data = Bluebox[:compute].create_block(@product_id, @template_id, 'password' => @password, 'lb_applications' => @lb_applications, 'lb_options' => @lb_options).body
      @lb_block_id = data['id']
      data
    end


    unless Fog.mocking?
      Bluebox[:compute].servers.get(@block_id).wait_for { ready? }
    end

    tests("get_block('#{@block_id}')").formats(@block_format) do
      pending if Fog.mocking?
      Bluebox[:compute].get_block(@block_id).body
    end

    tests("get_blocks").formats([@block_format.reject {|key,value| ['product', 'template'].include?(key)}]) do
      pending if Fog.mocking?
      Bluebox[:compute].get_blocks.body
    end

    tests("reboot_block('#{@block_id}')").formats({'status' => String, 'text' => String}) do
      pending if Fog.mocking?
      Bluebox[:compute].reboot_block(@block_id).body
    end

    unless Fog.mocking?
      Bluebox[:compute].servers.get(@block_id).wait_for { ready? }
    end

    tests("destroy_block('#{@block_id})'").formats({'text' => String}) do
      pending if Fog.mocking?
      Bluebox[:compute].destroy_block(@block_id).body
    end

    tests("destroy_block('#{@lb_block_id})'").formats({'text' => String}) do
      pending if Fog.mocking?
      Bluebox[:compute].destroy_block(@block_id).body
    end

  end

  tests('failure') do

    tests("get_block('00000000-0000-0000-0000-000000000000')").raises(Fog::Bluebox::Compute::NotFound) do
      pending if Fog.mocking?
      Bluebox[:compute].get_block('00000000-0000-0000-0000-000000000000')
    end

    tests("reboot_block('00000000-0000-0000-0000-000000000000')").raises(Fog::Bluebox::Compute::NotFound) do
      pending if Fog.mocking?
      Bluebox[:compute].reboot_block('00000000-0000-0000-0000-000000000000')
    end

    tests("destroy_block('00000000-0000-0000-0000-000000000000')").raises(Fog::Bluebox::Compute::NotFound) do
      pending if Fog.mocking?
      Bluebox[:compute].destroy_block('00000000-0000-0000-0000-000000000000')
    end

  end

end
