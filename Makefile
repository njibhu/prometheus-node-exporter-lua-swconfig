include $(TOPDIR)/rules.mk
 
PKG_NAME:=prometheus-node-exporter-lua-swconfig
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk
 
define Package/prometheus-node-exporter-lua-swconfig
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Prometheus node exporter (swconfig collector)
  PKGARCH:=all
endef

define Package/prometheus-node-exporter-lua-swconfig/description
  Provides node metrics as Prometheus scraping endpoint.

  This service is a lightweight rewrite in LUA of the offical Prometheus node_exporter.
endef
 
define Package/prometheus-node-exporter-lua-swconfig/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/prometheus-collectors
	$(INSTALL_BIN) ./files/usr/lib/lua/prometheus-collectors/swconfig.lua $(1)/usr/lib/lua/prometheus-collectors/
endef
 
$(eval $(call BuildPackage,prometheus-node-exporter-lua-swconfig))