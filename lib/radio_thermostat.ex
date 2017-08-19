defmodule RadioThermostat do
  use GenServer
  require Logger

  @days %{:mon => 0, :tue => 1, :wed => 2, :thu => 3, :fri => 4, :sat => 5, :sun => 6}
  @on_off %{:on => 2, :off => 1}
  @hold %{:on => 1, :off => 0}
  @tmode %{:heat => 1, :cool => 2, :auto => 3}
  @fmode %{:auto => 0, :auto_circulate => 1, :on => 2, :off => 0}
  @program_mode %{:program_a => 0, :program_b => 1, :vacation => 2, :holiday => 3}
  @resources %{
    :state => %{:key => "", :get => true, :post => false, :post_url => ""},
    :operating_mode => %{:key => "tmode", :get => true, :post => true, :post_url => "", :value => @tmode},
    :operating_state => %{:key => "tstate", :get => true, :post => false, :post_url => ""},
    :temp => %{:key => "temp", :get => true, :post => false, :post_url => ""},
    :fan => %{:key => "fmode", :get => true, :post => true, :post_url => "", :value => @fmode},
    :hold => %{:key => "hold", :get => true, :post => true, :post_url => "", :value => @hold},
    :temporary_heat => %{:key => "t_heat", :get => false, :post => true, :post_url => "", :value => :float},
    :temporary_cool => %{:key => "t_cool", :get => false, :post => true, :post_url => "", :value => :float},
    :absolute_heat => %{:key => "a_heat", :get => false, :post => true, :post_url => "", :value => :float},
    :absolute_cool => %{:key => "a_cool", :get => false, :post => true, :post_url => "", :value => :float},
    :time => %{:key => "time", :get => true, :post => true, :post_url => "", :value => :map},
    :program_mode => %{:key => "program_mode", :get => false, :post => true, :post_url => "", :value => @program_mode},
    :price_message => %{:key => "", :get => false, :post => true, :post_url => "/pma", :value => :map}
  }

  def start_link(url) do
    GenServer.start_link(__MODULE__, url)
  end

  def system(rt, path \\ "") do
    GenServer.call(rt, {:get, "/sys" <> path})
  end

  def state(rt) do
    get(rt, :state)
  end

  def set(rt, resource, value) do
    with %{:key => key, :post => post, :post_url => path, :value => parser} <- @resources[resource],
    true <- post do
      val =
        case parser do
          :float -> value
          :map -> value
          other -> other[value]
        end
        GenServer.call(rt, {:post, "/tstat" <> path, %{key => val}, resource}, 5000)
    end
  end

  def get(rt, resource) do
    with %{:key => key, :get => get} <- @resources[resource],
    true <- get,
    do: GenServer.call(rt, {:get, "/tstat/" <> key, resource}, 5000)
  end

  def init(url) do
    {:ok, %{:url => url}}
  end

  def handle_call({:get, path, resource}, {caller, _}, state) do
    {:ok, pid} = Task.start(fn ->
      case RadioThermostat.Client.do_get(path, state.url) do
        {:ok, response} ->
          send(caller, {resource, :ok, response})
        {:error, reason} ->
          send(caller, {resource, :error, reason})
      end
    end)
    {:reply, pid, state}
  end

  def handle_call({:post, path, value, resource}, {caller, _}, state) do
    {:ok, pid} = Task.start(fn ->
      case RadioThermostat.Client.do_post(path, state.url, value) do
        {:ok, response} ->
          send(caller, {resource, :ok, response})
        {:error, reason} ->
          send(caller, {resource, :error, reason})
      end
    end)
    {:reply, pid, state}
  end

  def handle_info(:timeout, state) do
    Logger.error "Call timed out. Keep on truckin..."
    {:noreply, state}
  end
end
