
/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  router = (
    var.router_name == ""
    ? google_compute_router.router[0].name
    : var.router_name
  )

  peer_external_gateway = (
    var.peer_external_gateway != null
    ? google_compute_external_vpn_gateway.external_gateway[0].self_link
    : null
  )
  #  secret = random_id.secret.b64_url
}

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  provider = google-beta
  name     = var.name
  project  = var.project_id
  region   = var.region
  network  = var.network
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  provider        = google-beta
  count           = var.peer_external_gateway != null ? 1 : 0
  name            = "external-${var.name}"
  project         = var.project_id
  redundancy_type = var.peer_external_gateway.redundancy_type
  description     = "Terraform managed external VPN gateway"
  dynamic "interface" {
    for_each = var.peer_external_gateway.interfaces
    content {
      id         = interface.value.id
      ip_address = interface.value.ip_address
    }
  }
}

resource "google_compute_router" "router" {
  provider = google-beta
  count    = var.router_name == "" ? 1 : 0
  name     = "gc-a-rtr-0001"
  project  = var.project_id
  region   = var.region
  network  = var.network
  bgp {
    advertise_mode = (
      var.router_advertise_config == null
      ? null
      : var.router_advertise_config.mode
    )
    advertised_groups = (
      var.router_advertise_config == null ? null : (
        var.router_advertise_config.mode != "CUSTOM"
        ? null
        : var.router_advertise_config.groups
      )
    )
    dynamic "advertised_ip_ranges" {
      for_each = (
        var.router_advertise_config == null ? {} : (
          var.router_advertise_config.mode != "CUSTOM"
          ? null
          : var.router_advertise_config.ip_ranges
        )
      )
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    asn = var.router_asn
  }
}

resource "google_compute_router_peer" "bgp_peer" {
  for_each        = var.tunnels
  region          = var.region
  project         = var.project_id
  name            = "${var.name}-${each.key}"
  router          = local.router
  peer_ip_address = each.value.bgp_peer.address
  peer_asn        = each.value.bgp_peer.asn
  advertised_route_priority = (
    each.value.bgp_peer_options == null ? var.route_priority : (
      each.value.bgp_peer_options.route_priority == null
      ? var.route_priority
      : each.value.bgp_peer_options.route_priority
    )
  )
  advertise_mode = (
    each.value.bgp_peer_options == null ? null : each.value.bgp_peer_options.advertise_mode
  )
  advertised_groups = (
    each.value.bgp_peer_options == null ? null : (
      each.value.bgp_peer_options.advertise_mode != "CUSTOM"
      ? null
      : each.value.bgp_peer_options.advertise_groups
    )
  )
  dynamic "advertised_ip_ranges" {
    for_each = (
      each.value.bgp_peer_options == null ? {} : (
        each.value.bgp_peer_options.advertise_mode != "CUSTOM"
        ? {}
        : each.value.bgp_peer_options.advertise_ip_ranges
      )
    )
    iterator = range
    content {
      range       = range.key
      description = range.value
    }
  }
  interface = google_compute_router_interface.router_interface[each.key].name
}

resource "google_compute_router_interface" "router_interface" {
  provider   = google-beta
  for_each   = var.tunnels
  project    = var.project_id
  region     = var.region
  name       = "${var.name}-${each.key}"
  router     = local.router
  ip_range   = each.value.bgp_session_range == "" ? null : each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

resource "google_compute_vpn_tunnel" "tunnels" {
  provider                        = google-beta
  for_each                        = var.tunnels
  project                         = var.project_id
  region                          = var.region
  name                            = "${var.name}-${each.key}"
  router                          = local.router
  peer_external_gateway           = local.peer_external_gateway
  peer_external_gateway_interface = each.value.peer_external_gateway_interface
  peer_gcp_gateway                = var.peer_gcp_gateway
  vpn_gateway_interface           = each.value.vpn_gateway_interface
  ike_version                     = each.value.ike_version
  shared_secret                   = each.value.shared_secret == "" ? data.google_secret_manager_secret_version.this.secret_data : each.value.shared_secret
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway.self_link
}

#resource "random_id" "secret" {
#  byte_length = 8
#}

resource "google_project_service" "project" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
}

data "google_secret_manager_secret_version" "this" {
  provider = google-beta
  secret   = google_secret_manager_secret.this.id
  version  = var.secret_version
}


resource "google_secret_manager_secret" "this" {
  project   = var.project_id
  secret_id = var.secret_id

  replication {
    user_managed {
      replicas {
        location = "europe-west2"
      }
    }
  }
  depends_on = [google_project_service.project]
}
