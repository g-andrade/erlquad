defmodule erlquad.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :erlquad,
     version: @version,
     description: "Erlang quadtree"
     package: package]
  end

  defp package do
    [files: ~w(src rebar.config README.md LICENSE),
     contributors: ["Guilherme Andrade"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/g-andrade/erlquad"}]
  end
end
