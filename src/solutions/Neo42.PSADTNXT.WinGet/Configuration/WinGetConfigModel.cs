using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Json;
using System.Text;

namespace PSADTNXT.WinGet.Configuration
{
	public record WinGetConfigModel
	{
		public string? ProductCode { get; set; }

		public string? PackageFamilyName { get; set; }

		public string? MinimumOSVersion { get; set; }

		public List<AppsAndFeaturesEntryModel>? AppsAndFeaturesEntries { get; set; }

		public static WinGetConfigModel Create(string path)
		{
			var json = File.ReadAllText(path);
			var serializer = new DataContractJsonSerializer(typeof(WinGetConfigModel));
			using var ms = new MemoryStream(Encoding.UTF8.GetBytes(json));
			return serializer.ReadObject(ms) is WinGetConfigModel model
				? model
				: throw new InvalidOperationException("Could not parse the input data as WinGetConfigModel.");
		}
	}
}
