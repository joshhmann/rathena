// Copyright (c) rAthena Dev Teams - Licensed under GNU GPL
// For more information, see LICENCE in the main folder

#ifndef CHRIF_HPP
#define CHRIF_HPP

#include <ctime>
#include <string>

#include <common/cbasetypes.hpp>
#include <common/mmo.hpp> // NAME_LENGTH
#include <common/timer.hpp> // t_tick
#include <common/socket.hpp> // enum chrif_req_op

//fwd declaration
class map_session_data;

enum sd_state { ST_LOGIN, ST_LOGOUT, ST_MAPCHANGE };

enum e_chrif_save_opt {
	CSAVE_NORMAL = 0x00,		/// Normal
	CSAVE_QUIT = 0x01,				/// Character quitting
	CSAVE_CHANGE_MAPSERV = 0x02,	/// Character changing map server
	CSAVE_AUTOTRADE = 0x04,		/// Character entering autotrade state
	CSAVE_INVENTORY = 0x08,		/// Inventory data changed
	CSAVE_CART = 0x10,				/// Cart data changed
	CSAVE_QUITTING = CSAVE_QUIT|CSAVE_CHANGE_MAPSERV|CSAVE_AUTOTRADE,
};

enum e_headlesspc_status {
	HEADLESSPC_STATUS_ABSENT = 0,
	HEADLESSPC_STATUS_PENDING_SPAWN = 1,
	HEADLESSPC_STATUS_ACTIVE = 2,
	HEADLESSPC_STATUS_PENDING_REMOVE = 3,
	HEADLESSPC_STATUS_OCCUPIED = 4,
};

enum e_headlesspc_reconcile_result {
	HEADLESSPC_RECONCILE_NONE = 0,
	HEADLESSPC_RECONCILE_RECONCILED = 1,
	HEADLESSPC_RECONCILE_ALREADY_CLEAR = 2,
	HEADLESSPC_RECONCILE_REFUSED_OTHER_SERVER = 3,
	HEADLESSPC_RECONCILE_REFUSED_LOCAL = 4,
	HEADLESSPC_RECONCILE_INVALID_CHAR = 5,
};

struct auth_node {
	uint32 account_id, char_id;
	int32 login_id1, login_id2, sex, fd;
	time_t expiration_time; // # of seconds 1/1/1970 (timestamp): Validity limit of the account (0 = unlimited)
	map_session_data *sd;	//Data from logged on char.
	struct mmo_charstatus *char_dat;	//Data from char server.
	t_tick node_created; //timestamp for node timeouts
	enum sd_state state; //To track whether player was login in/out or changing maps.
};

void chrif_setuserid(char* id);
void chrif_setpasswd(char* pwd);
void chrif_checkdefaultlogin(void);
int32 chrif_setip(const char* ip);
void chrif_setport(uint16 port);

int32 chrif_isconnected(void);

extern int32 chrif_connected;
extern int32 other_mapserver_count;
extern char charserver_name[NAME_LENGTH];

struct auth_node* chrif_search(uint32 account_id);
struct auth_node* chrif_auth_check(uint32 account_id, uint32 char_id, enum sd_state state);
bool chrif_auth_delete(uint32 account_id, uint32 char_id, enum sd_state state);
bool chrif_auth_finished( const map_session_data* sd );

void chrif_authreq(map_session_data* sd, bool autotrade);
void chrif_authok(int32 fd);
int32 chrif_scdata_request(uint32 account_id, uint32 char_id);
int32 chrif_skillcooldown_request(uint32 account_id, uint32 char_id);
int32 chrif_skillcooldown_save( const map_session_data& sd );
int32 chrif_skillcooldown_load(int32 fd);

int32 chrif_save(map_session_data* sd, int32 flag);
int32 chrif_charselectreq(map_session_data* sd, uint32 s_ip);
int32 chrif_changemapserver(map_session_data* sd, uint32 ip, uint16 port);

int32 chrif_searchcharid(uint32 char_id);
int32 chrif_changeemail(int32 id, const char *actual_email, const char *new_email);
int32 chrif_req_login_operation(int32 aid, const char* character_name, enum chrif_req_op operation_type, int32 timediff, int32 val1, int32 val2);
int32 chrif_updatefamelist( const map_session_data& sd, e_rank ranktype );
int32 chrif_buildfamelist(void);
int32 chrif_save_scdata( const map_session_data* sd );
int32 chrif_char_offline( const map_session_data* sd );
int32 chrif_char_offline_nsd(uint32 account_id, uint32 char_id);
int32 chrif_char_reset_offline(void);
int32 send_users_tochar(void);
int32 chrif_char_online( const map_session_data* sd );
int32 chrif_changesex(map_session_data *sd, bool change_account);
int32 chrif_divorce(int32 partner_id1, int32 partner_id2);

int32 chrif_removefriend(uint32 char_id, int32 friend_id);

void chrif_parse_ack_vipActive(int32 fd);

int32 chrif_req_charban(int32 aid, const char* character_name, int32 timediff);
int32 chrif_req_charunban(int32 aid, const char* character_name);

int32 chrif_bsdata_request(uint32 char_id);
int32 chrif_bsdata_save(map_session_data *sd, bool quit);
bool chrif_headlesspc_request_spawn(uint32 char_id, int16 m, uint16 x, uint16 y);
bool chrif_headlesspc_remove(uint32 char_id);
bool chrif_headlesspc_request_reconcile(uint32 char_id);
bool chrif_headlesspc_setpos(uint32 char_id, int16 m, uint16 x, uint16 y);
bool chrif_headlesspc_walkto(uint32 char_id, uint16 x, uint16 y);
bool chrif_headlesspc_claim(uint32 char_id, const char* owner);
bool chrif_headlesspc_release(uint32 char_id, const char* owner);
bool chrif_headlesspc_owned_remove(uint32 char_id, const char* owner);
bool chrif_headlesspc_owned_setpos(uint32 char_id, const char* owner, int16 m, uint16 x, uint16 y);
bool chrif_headlesspc_owned_walkto(uint32 char_id, const char* owner, uint16 x, uint16 y);
bool chrif_headlesspc_owned_routeclear(uint32 char_id, const char* owner);
bool chrif_headlesspc_owned_routeadd(uint32 char_id, const char* owner, uint16 x, uint16 y);
bool chrif_headlesspc_owned_routestart(uint32 char_id, const char* owner, bool loop);
bool chrif_headlesspc_owned_routestop(uint32 char_id, const char* owner);
bool chrif_headlesspc_routeclear(uint32 char_id);
bool chrif_headlesspc_routeadd(uint32 char_id, uint16 x, uint16 y);
bool chrif_headlesspc_routestart(uint32 char_id, bool loop);
bool chrif_headlesspc_routestop(uint32 char_id);
int32 chrif_headlesspc_restoreall(void);
int32 chrif_headlesspc_status(uint32 char_id);
int32 chrif_headlesspc_routestatus(uint32 char_id);
std::string chrif_headlesspc_owner(uint32 char_id);
uint32 chrif_headlesspc_ack(uint32 char_id);
uint32 chrif_headlesspc_spawn_ack(uint32 char_id);
uint32 chrif_headlesspc_reconcile_ack(uint32 char_id);
uint32 chrif_headlesspc_walk_ack(uint32 char_id);
int32 chrif_headlesspc_reconcile_result(uint32 char_id);
void chrif_headlesspc_mark_spawn_ready(uint32 char_id);

void do_final_chrif(void);
void do_init_chrif(void);

int32 chrif_flush_fifo(void);

#endif /* CHRIF_HPP */
