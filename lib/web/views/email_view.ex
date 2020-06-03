defmodule Mobilizon.Web.EmailView do
  use Mobilizon.Web, :view

  import Mobilizon.Web.Gettext

  def datetime_to_string(%DateTime{} = datetime, locale \\ "en", format \\ :medium) do
    with {:ok, string} <-
           Mobilizon.Cldr.DateTime.to_string(datetime, format: format, locale: locale) do
      string
    end
  end

  def datetime_to_time_string(%DateTime{} = datetime, locale \\ "en", format \\ :hm) do
    with {:ok, string} <-
           Mobilizon.Cldr.DateTime.to_string(datetime, format: format, locale: locale) do
      string
    end
  end
end
