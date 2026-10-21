using System;
using System.Collections.Generic;
using System.Xml;

namespace PSADTNXT.Extensions
{
	public static class NxtXmlExtensions
	{
		private const string XMLNS_NAMESPACE_URI = "http://www.w3.org/2000/xmlns/";

		/// <summary>
		/// Creates an XmlNamespaceManager containing all namespaces in scope of the given node and all namespaces declared on its descendants.
		/// If a prefix is bound to different namespaces, the first binding wins (bindings in scope of the node first, then descendants in document order).
		/// As XPath 1.0 can not match unprefixed names against a default namespace, each distinct default namespace is additionally
		/// registered under <paramref name="defaultNamespacePrefix"/>, suffixed with a number if the prefix is already taken (e.g. ns, ns1, ns2).
		/// This allows XPath queries like <c>/ns:root/ns:child</c> on documents using a default namespace.
		/// </summary>
		/// <param name="node">The node or document to collect the namespaces from.</param>
		/// <param name="defaultNamespacePrefix">The prefix under which default namespaces are made available to XPath.</param>
		public static XmlNamespaceManager GetNsManager(this XmlNode node, string defaultNamespacePrefix = "ns")
		{
			if (node is null)
			{
				throw new ArgumentNullException(nameof(node));
			}
			if (string.IsNullOrEmpty(defaultNamespacePrefix) || defaultNamespacePrefix.StartsWith("xml", StringComparison.OrdinalIgnoreCase))
			{
				throw new ArgumentException("The default namespace prefix must not be empty or start with 'xml'.", nameof(defaultNamespacePrefix));
			}
			_ = XmlConvert.VerifyNCName(defaultNamespacePrefix);

			var document = node as XmlDocument ?? node.OwnerDocument ?? throw new InvalidOperationException("Could not determine OwnerDocument for given XML Node.");
			var manager = new XmlNamespaceManager(document.NameTable);
			var defaultNamespaces = new List<string>();

			// Namespaces declared on the node itself or any of its ancestors.
			var contextElement = node as XmlElement ?? (node as XmlAttribute)?.OwnerElement ?? node.ParentNode as XmlElement;
			if (contextElement?.CreateNavigator() is { } navigator)
			{
				foreach (var binding in navigator.GetNamespacesInScope(XmlNamespaceScope.ExcludeXml))
				{
					AddBinding(manager, defaultNamespaces, binding.Key, binding.Value);
				}
			}
			if (contextElement is not null)
			{
				AddUsedPrefixes(manager, defaultNamespaces, contextElement);
			}

			// Namespaces declared or used below the node.
			if (node.SelectNodes("descendant::*") is { } descendants)
			{
				foreach (XmlElement element in descendants)
				{
					foreach (XmlAttribute attr in element.Attributes)
					{
						if (attr.NamespaceURI == XMLNS_NAMESPACE_URI)
						{
							AddBinding(manager, defaultNamespaces, attr.Prefix.Length == 0 ? string.Empty : attr.LocalName, attr.Value);
						}
					}
					AddUsedPrefixes(manager, defaultNamespaces, element);
				}
			}

			// Explicit prefixes are registered first so synthetic default namespace prefixes never shadow them.
			if (defaultNamespaces.Count > 0)
			{
				manager.AddNamespace(string.Empty, defaultNamespaces[0]);
			}
			var index = 0;
			foreach (var uri in defaultNamespaces)
			{
				var prefix = defaultNamespacePrefix;
				while (manager.LookupNamespace(prefix) is string boundUri && boundUri != uri)
				{
					prefix = defaultNamespacePrefix + ++index;
				}
				if (manager.LookupNamespace(prefix) is null)
				{
					manager.AddNamespace(prefix, uri);
				}
			}

			return manager;
		}

		/// <summary>
		/// Adds the prefixes used by the element and its attributes. Nodes created in memory (e.g. via CreateElement(prefix, localName, namespaceURI))
		/// are not backed by an xmlns attribute until the document is saved and reloaded.
		/// </summary>
		private static void AddUsedPrefixes(XmlNamespaceManager manager, List<string> defaultNamespaces, XmlElement element)
		{
			if (element.Prefix.Length > 0)
			{
				AddBinding(manager, defaultNamespaces, element.Prefix, element.NamespaceURI);
			}
			foreach (XmlAttribute attr in element.Attributes)
			{
				if (attr.Prefix.Length > 0 && attr.NamespaceURI != XMLNS_NAMESPACE_URI)
				{
					AddBinding(manager, defaultNamespaces, attr.Prefix, attr.NamespaceURI);
				}
			}
		}

		private static void AddBinding(XmlNamespaceManager manager, List<string> defaultNamespaces, string prefix, string uri)
		{
			// Skip undeclarations (xmlns="") as a prefix can not be bound to an empty namespace.
			if (uri.Length == 0)
			{
				return;
			}
			if (prefix.Length == 0)
			{
				if (!defaultNamespaces.Contains(uri))
				{
					defaultNamespaces.Add(uri);
				}
				return;
			}
			// The xml and xmlns prefixes are predefined and can not be redeclared on the XmlNamespaceManager.
			if (prefix is "xml" or "xmlns")
			{
				return;
			}
			if (manager.LookupNamespace(prefix) is null)
			{
				manager.AddNamespace(prefix, uri);
			}
		}
	}
}
