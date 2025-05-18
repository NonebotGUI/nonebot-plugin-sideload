import ast
import nonebot.exception
from nonebot.plugin import PluginMetadata
from nonebot.log import logger
from nonebot import get_driver, on_notice
from nonebot.adapters.onebot.v11 import Bot, Event, PrivateMessageEvent, GroupMessageEvent, GroupRecallNoticeEvent, FriendRecallNoticeEvent
from os import path
import nonebot
from nonebot.drivers import URL, ASGIMixin, WebSocket, WebSocketServerSetup, HTTPServerSetup, Request, Response
import httpx
from nonebot.message import event_preprocessor
import aiosqlite
from nonebot import require
require("nonebot_plugin_localstore")
import nonebot_plugin_localstore as store
from nonebot import get_plugin_config
from .config import Config
import datetime
import json
from pathlib import Path
import os

plugin_config = get_plugin_config(Config)
password = plugin_config.sideload_password
data_dir = store.get_plugin_data_dir()
driver = get_driver()


__plugin_meta__ = PluginMetadata(
    name="Web侧载",
    description="为你的NoneBot侧载一个OneBot V11 Web聊天面板",
    usage="连接Bot即可使用",
    type="application",
    homepage="https://github.com/NonebotGUI/nonebot-plugin-sideload",
    config=Config,
    supported_adapters={"~onebot.v11"},
)


# 画个LOGO(?)
logger.success('  _   _                  ____        _      ')
logger.success(' | \ | | ___  _ __   ___| __ )  ___ | |_    ')
logger.success(' |  \| |/ _ \|  _ \ / _ \  _ \ / _ \| __|   ')
logger.success(' | |\  | (_) | | | |  __/ |_) | (_) | |_    ')
logger.success(' |_| \_|\___/|_| |_|\___|____/ \___/ \__|   ')
logger.success(' / ___|(_) __| | ___| |    ___   __ _  __| |')
logger.success(' \___ \| |/ _` |/ _ \ |   / _ \ / _` |/ _` |')
logger.success('  ___) | | (_| |  __/ |__| (_) | (_| | (_| |')
logger.success(' |____/|_|\__,_|\___|_____\___/ \__,_|\__,_|')

logger.warning('等待Bot连接...')
global is_connected
is_connected = False



# 初始化数据库
@driver.on_bot_connect
async def handle_bot_connect(bot: Bot):
    global group_avatar_dir, friend_avatar_dir, image_dir, is_connected
    # 创建目录
    group_avatar_dir = Path(f'{str(data_dir)}/group_avatar')
    if not group_avatar_dir.exists():
        os.makedirs(group_avatar_dir)
    friend_avatar_dir = Path(f'{str(data_dir)}/friend_avatar')
    if not friend_avatar_dir.exists():
        os.makedirs(friend_avatar_dir)
    image_dir = Path(f'{str(data_dir)}/image')
    if not image_dir.exists():
        os.makedirs(image_dir)
    is_connected = True
    global bot_id, bot_nickname
    bot_id = bot.self_id
    nickname = await bot.call_api('get_login_info')
    nickname = nickname['nickname']
    bot_nickname = str(nickname)
    # 尝试拿用户ip
    try:
        import netifaces
        def get_all_network_ips():
            """获取所有网络接口的IP地址（排除回环接口）"""
            ipv4_list = []
            ipv6_list = []
            interfaces = netifaces.interfaces()
            for interface in interfaces:

                if interface.startswith('lo'):
                    continue
                try:
                    addresses = netifaces.ifaddresses(interface)
                    if netifaces.AF_INET in addresses:  
                        for addr in addresses[netifaces.AF_INET]:
                            ip = addr['addr']
                            if not ip.startswith('127.'):
                                ipv4_list.append(ip)
                    if netifaces.AF_INET6 in addresses:
                        for addr in addresses[netifaces.AF_INET6]:
                            ip = addr['addr']
                            if not ip.startswith('fe80:'):
                                if '%' in ip:
                                    ip = ip.split('%')[0]
                                ipv6_list.append(ip)
                except Exception:
                    pass
            return {"ipv4": ipv4_list, "ipv6": ipv6_list}
        public_ips = get_all_network_ips()

        logger.success("=====================================================")
        if public_ips["ipv4"] or public_ips["ipv6"]:
            logger.success(f"Bot {bot_id} 已连接，现在可以访问以下地址进入WebUI:")
            for ip in public_ips["ipv4"]:
                logger.success(f"http://{ip}:{nonebot.get_driver().config.port}/nbgui/v1/sideload")
                logger.success(f"WebSocket 地址: ws://{ip}:{nonebot.get_driver().config.port}/nbgui/v1/sideload/ws")
            for ip in public_ips["ipv6"]:
                logger.success(f"http://[{ip}]:{nonebot.get_driver().config.port}/nbgui/v1/sideload")
                logger.success(f"WebSocket 地址: ws://[{ip}]:{nonebot.get_driver().config.port}/nbgui/v1/sideload/ws")
        else:
            logger.warning('获取IP地址失败')
            logger.success(f"Bot {bot_id} 已连接，现在可以访问 http://ip:port/nbgui/v1/sideload 进入 WebUI")
            logger.success(f"Websocket 地址为 ws://ip:port/nbgui/v1/sideload/ws")
        logger.success("=====================================================")
    except ImportError:
        # 如果没有安装netifaces，则使用socket模块作为备选
        try:
            import socket
            hostname = socket.gethostname()
            ip_addresses = socket.gethostbyname_ex(hostname)[2]
            public_ips = [ip for ip in ip_addresses if not ip.startswith('127.')]
            
            logger.success("=====================================================")
            if public_ips:
                logger.success(f"Bot {bot_id} 已连接，现在可以访问以下地址进入WebUI:")
                for ip in public_ips:
                    logger.success(f"http://{ip}:{nonebot.get_driver().config.port}/nbgui/v1/sideload")
                    logger.success(f"WebSocket 地址: ws://{ip}:{nonebot.get_driver().config.port}/nbgui/v1/sideload/ws")
            else:
                logger.warning('获取IP地址失败')
                logger.success(f"Bot {bot_id} 已连接，现在可以访问 http://ip:port/nbgui/v1/sideload 进入 WebUI")
                logger.success(f"Websocket 地址为 ws://ip:port/nbgui/v1/sideload/ws")
            logger.success("=====================================================")
        except Exception as e:
            logger.error(f"获取IP地址失败: {e}")
            logger.success(f"Bot {bot_id} 已连接，现在可以访问 http://ip:port/nbgui/v1/sideload 进入 WebUI")
    db_path = str(data_dir) + f'/{bot_id}.db'
    global db, cursor, rec, sen
    # 连接数据库
    db = await aiosqlite.connect(db_path)
    cursor = await db.cursor()
    await cursor.execute('''
        CREATE TABLE IF NOT EXISTS total(
            id text,
            nickname text,
            sended int,
            received int,
            group_list text,
            friend_list text
        )
    ''')
    
    await cursor.execute('''
        CREATE TABLE IF NOT EXISTS groups(
            id text,
            group_name text,
            sender text,
            message text,
            type text,
            msg_id text,
            time text,
            drawed text
        )''')

    await cursor.execute('''
        CREATE TABLE IF NOT EXISTS friends(
            id text,
            nickname text,
            message text,
            sender text,
            type text,
            msg_id text,
            time text,
            drawed text
        )''')

    await cursor.execute('SELECT COUNT(*) FROM total WHERE id = ? AND nickname = ?', (bot_id, nickname))
    result = await cursor.fetchone()
    if result[0] == 0:
        await cursor.execute('INSERT INTO total (id, nickname, sended, received) VALUES (?, ?, 0, 0)', (bot_id, nickname))
    
    await cursor.execute('SELECT received FROM total WHERE id = ?', (bot_id,))
    received = (await cursor.fetchone())[0]
    rec = received
    
    await cursor.execute('SELECT sended FROM total WHERE id = ?', (bot_id,))
    sended = (await cursor.fetchone())[0]
    sen = sended
    
    group_list = await bot.call_api('get_group_list')
    friend_list = await bot.call_api('get_friend_list')
    
    await cursor.execute('UPDATE total SET group_list = ? WHERE id = ?', (str(group_list), bot_id))
    await cursor.execute('UPDATE total SET friend_list = ? WHERE id = ?', (str(friend_list), bot_id))
    await db.commit()

@driver.on_bot_disconnect
async def handle_bot_disconnect(bot: Bot):
    global is_connected
    is_connected = False
    if db:
        await cursor.close()
        await db.close()

# 统计接收消息数量
@event_preprocessor
async def _(bot: Bot, event: Event):
    if event.get_type() == "message":
        # global rec
        # rec += 1
        await cursor.execute('UPDATE total SET received = ? WHERE id = ?', (rec, bot.self_id))
        await db.commit()
    return

# 记录群消息
@event_preprocessor
async def handle_group_message(bot: Bot, event: GroupMessageEvent):
    time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    group_id = event.group_id
    uid = event.get_user_id()
    nickname = event.sender.nickname
    sender = {
        "user_id": uid,
        "nickname": nickname
    }
    msg_id = event.message_id

    message = "暂不支持该消息类型"
    msg_type = "unknown"

    for i in event.message:
        if i.type == 'image':
            msg_type = 'image'
            message = i.data['url'].replace('https://', 'http://')
            await cursor.execute('INSERT INTO groups (id, group_name, message, sender, type, msg_id, time, drawed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
                            (group_id, group_id, message, str(sender), msg_type, msg_id, time, '0'))
            await db.commit()
        elif i.type == 'text':
            msg_type = 'text'
            message = i.data['text']
            await cursor.execute('INSERT INTO groups (id, group_name, message, sender, type, msg_id, time, drawed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
                            (group_id, group_id, message, str(sender), msg_type, msg_id, time, '0'))
            await db.commit()
    return

# 监听群事件
group_notice = on_notice(rule=lambda event: isinstance(event, GroupRecallNoticeEvent))
@group_notice.handle()
async def handle_group_notice(bot: Bot, event: GroupRecallNoticeEvent):
    mid = event.message_id
    gid = event.group_id
    await cursor.execute('UPDATE groups SET drawed = ? WHERE msg_id = ? AND id = ?', ('1', mid, gid))
    await db.commit()
    return

# 记录私聊消息
@event_preprocessor
async def handle_private_message(bot: Bot, event: PrivateMessageEvent):
    time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    id = event.get_user_id()
    nickname = event.sender.nickname
    msg_id = event.message_id
    sender = {
        "user_id": id,
        "nickname": nickname
    }
    message = "暂不支持该消息类型"
    msg_type = "unknown"
    for i in event.message:
        if i.type == 'image':
            msg_type = 'image'
            message = i.data['url'].replace('https://', 'http://')
            await cursor.execute('INSERT INTO friends (id, nickname, message, sender, type, msg_id, time, drawed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
                        (id, nickname, message, str(sender), msg_type, msg_id, time, '0'))
            await db.commit()
        elif i.type == 'text':
            msg_type = 'text'
            message = i.data['text']
            await cursor.execute('INSERT INTO friends (id, nickname, message, sender, type, msg_id, time, drawed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
                        (id, nickname, message, str(sender), msg_type, msg_id, time, '0'))
            await db.commit()
        elif i.type == 'video':
            msg_type = 'video'
            message = i.data['url']
            await cursor.execute('INSERT INTO friends (id, nickname, message, sender, type, msg_id, time, drawed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
                        (id, nickname, message, str(sender), msg_type, msg_id, time, '0'))
            await db.commit()
    return

# 监听私聊事件
friend_notice = on_notice(rule=lambda event: isinstance(event, FriendRecallNoticeEvent))
@friend_notice.handle()
async def handle_friend_notice(bot: Bot, event: FriendRecallNoticeEvent):
    mid = event.message_id
    fid = event.user_id
    await cursor.execute('UPDATE friends SET drawed = ? WHERE msg_id = ? AND id = ?', ('1', mid, fid))
    await db.commit()
    return


async def webui_main(request: Request) -> Response:
    if (is_connected):
        webui_path = path.join(path.dirname(__file__), "web")
        file_path = path.join(webui_path, request.url.path.replace("/nbgui/v1/sideload", "").lstrip("/"))
        if path.isdir(file_path):
            file_path = path.join(file_path, "index.html")
        if not path.exists(file_path):
            return Response(404, content="File not found")
        file_extension = path.splitext(file_path)[1].lower()
        mime_types = {
            '.html': 'text/html',
            '.css': 'text/css',
            '.js': 'application/javascript',
            '.json': 'application/json',
            '.png': 'image/png',
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.gif': 'image/gif',
            '.svg': 'image/svg+xml',
            '.ttf': 'font/ttf',
            '.woff': 'font/woff',
            '.woff2': 'font/woff2',
            '.ico': 'image/x-icon'
        }
        content_type = mime_types.get(file_extension, 'application/octet-stream')
        if content_type.startswith('image/') or content_type.startswith('font/') or content_type == 'application/octet-stream':
            with open(file_path, "rb") as file:
                content = file.read()
        else:
            with open(file_path, "r", encoding="utf-8") as file:
                content = file.read()

        return Response(200, content=content, headers={"Content-Type": content_type})
    else:
        return Response(503, content="Bot is not connected")


# 沟槽的跨域
# 用户头像
async def user_avatar(request: Request) -> Response:
    file_path = path.join(friend_avatar_dir, request.url.path.replace("/sideload/avatars/user", "").lstrip("/"))
    if path.isdir(file_path):
        return Response(404, content="File not found")
    if not path.exists(file_path):
        httpx_client = httpx.AsyncClient()
        res = await httpx_client.get('http://q1.qlogo.cn/g?b=qq&nk='+request.url.path.replace("/sideload/avatars/user", "").replace(".png", "").lstrip("/")+'&s=100', headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'})
        if res.status_code != 200:
            return Response(404, content="File not found")
        # 保存头像
        with open(file_path, "wb") as f:
            f.write(res.content)
    file_extension = path.splitext(file_path)[1].lower()
    mime_types = {
        '.png': 'image/png',
        '.gif': 'image/gif'
    }
    content_type = mime_types.get(file_extension, 'application/octet-stream')
    if content_type.startswith('image/'):
        with open(file_path, "rb") as file:
            content = file.read()
    else:
        with open(file_path, "r", encoding="utf-8") as file:
            content = file.read()

    return Response(200, content=content, headers={"Content-Type": content_type})

# 群组头像
async def group_avatar(request: Request) -> Response:
    file_path = path.join(group_avatar_dir, request.url.path.replace("/sideload/avatars/group", "").lstrip("/"))
    if path.isdir(file_path):
        return Response(404, content="File not found")
    if not path.exists(file_path):
        httpx_client = httpx.AsyncClient()
        gid = request.url.path.replace("/sideload/avatars/group", "").replace(".png", "").lstrip("/")
        res = await httpx_client.get(f'https://p.qlogo.cn/gh/{gid}/{gid}/100/', headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'})
        if res.status_code != 200:
            return Response(404, content="File not found")
        with open(file_path, "wb") as f:
            f.write(res.content)
    file_extension = path.splitext(file_path)[1].lower()
    mime_types = {
        '.png': 'image/png',
        '.gif': 'image/gif'
    }
    content_type = mime_types.get(file_extension, 'application/octet-stream')
    if content_type.startswith('image/'):
        with open(file_path, "rb") as file:
            content = file.read()
    else:
        with open(file_path, "r", encoding="utf-8") as file:
            content = file.read()

    return Response(200, content=content, headers={"Content-Type": content_type})

# 图片
async def image(request: Request) -> Response:
    file_path = path.join(image_dir, request.url.path.replace("/sideload/image", "").lstrip("/"))
    if path.isdir(file_path):
        return Response(404, content="File not found")
    if not path.exists(file_path):
        httpx_client = httpx.AsyncClient()
        msg_id = request.url.path.replace("/sideload/image", "").lstrip("/")
        await cursor.execute('SELECT message FROM groups WHERE msg_id = ?', (msg_id,))
        result = await cursor.fetchone()
        if result:
            img = result[0]
        else:
            await cursor.execute('SELECT message FROM friends WHERE msg_id = ?', (msg_id,))
            result = await cursor.fetchone()
            if result:
                img = result[0]
            else:
                return Response(404, content="Image URL not found")
        try:
            res = await httpx_client.get(f'{img}', headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'})
            if res.status_code != 200:
                return Response(404, content="Failed to fetch image")
            with open(file_path, "wb") as f:
                f.write(res.content)
        except Exception as e:
            logger.error(f"Error fetching image: {e}")
            return Response(500, content=f"Error fetching image: {e}")
    try:
        with open(file_path, "rb") as file:
            content = file.read()
            content_type = 'image/jpeg'
        return Response(200, content=content, headers={"Content-Type": content_type})
    except Exception as e:
        logger.error(f"Error reading image file: {e}")
        return Response(500, content=f"Error reading image file: {e}")

# 验证密码
async def auth(request: Request) -> Response:
    body = request.content
    if isinstance(body, bytes):
        body_str = body.decode('utf-8')
    else:
        body_str = body
    data = json.loads(body_str)
    if 'password' not in data or data['password'] != password:
        return Response(403, content="Unauthorized")
    return Response(200, content="OK")


# WebSocket处理
async def ws_handler(ws: WebSocket):
    await ws.accept()
    try:
        while True:
            rec_msg = await ws.receive_text()
            rec_msg = json.loads(rec_msg)
            bot = nonebot.get_bot()
            if rec_msg['password'] == password:
                type = rec_msg['type']
                if type == 'get_total':
                    await cursor.execute('SELECT * FROM total WHERE id = ?', (bot_id,))
                    total = await cursor.fetchone()
                    group_list = ast.literal_eval(total[4]) if total[4] else []
                    friend_list = ast.literal_eval(total[5]) if total[5] else []
                    res = {
                        'type': 'total',
                        "data": {
                            "id": str(total[0]),
                            "nickname": total[1],
                            "sended": total[2],
                            "received": total[3],
                            "group_list": group_list,
                            "friend_list": friend_list
                        }
                    }
                    await ws.send_text(json.dumps(res, ensure_ascii=False))
                elif type == 'send_private_msg':
                    time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
                    user_id = rec_msg['user_id']
                    message = rec_msg['message']
                    res = await bot.call_api(api='send_private_msg', user_id=user_id, message=message)
                    id = bot_id
                    nickname = bot_nickname
                    sender = {
                        "user_id": id,
                        "nickname": nickname
                    }
                    await cursor.execute('INSERT INTO friends (id, nickname, message, sender, type, msg_id, time, drawed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', (user_id, user_id, message, str(sender), "text", str(res['message_id']), time, '0'))
                    await db.commit()
                    ws_res = {
                        'type': 'send_private_msg',
                        'data': res
                    }
                    await ws.send_text(json.dumps(ws_res, ensure_ascii=False))
                elif type == 'send_group_msg':
                    time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
                    group_id = rec_msg['group_id']
                    message = rec_msg['message']
                    res = await bot.call_api(api='send_group_msg', group_id=group_id, message=message)
                    id = bot_id
                    nickname = bot_nickname
                    sender = {
                        "user_id": id,
                        "nickname": nickname
                    }
                    await cursor.execute('INSERT INTO groups (id, group_name, message, sender, type, msg_id, time, drawed) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', (group_id, group_id, message, str(sender), "text", str(res['message_id']), time, '0'))
                    await db.commit()
                    ws_res = {
                        'type': 'send_group_msg',
                        'data': res
                    }
                    await ws.send_text(json.dumps(ws_res, ensure_ascii=False))
                elif type == 'get_group_message':
                    group_id = rec_msg['group_id']
                    await cursor.execute('SELECT * FROM groups WHERE id = ?', (group_id,))
                    messages = await cursor.fetchall()
                    res = {
                        'type': 'group_msg',
                        'data': []
                    }
                    for message in messages:
                        res['data'].append({
                            'group_name': message[1],
                            'sender': ast.literal_eval(message[2]),
                            'message': message[3],
                            'type': message[4],
                            'msg_id': message[5],
                            'time': message[6],
                            'drawed': message[7]
                        })
                    await ws.send_text(json.dumps(res, ensure_ascii=False))
                elif type == 'get_friend_message':
                    user_id = rec_msg['user_id']
                    await cursor.execute('SELECT * FROM friends WHERE id = ?', (user_id,))
                    messages = await cursor.fetchall()
                    res = {
                        'type': 'friend_msg',
                        'data': []
                    }
                    for message in messages:
                        res['data'].append({
                            'nickname': message[1],
                            'message': message[2],
                            'sender': ast.literal_eval(message[3]),
                            'type': message[4],
                            'msg_id': message[5],
                            'time': message[6],
                            'drawed': message[7]
                        })
                    await ws.send_text(json.dumps(res, ensure_ascii=False))
                elif type == 'send_like':
                    user_id = rec_msg['user_id']
                    time = rec_msg['time']
                    await bot.call_api(api='send_like', user_id=user_id, time=time)
                    await ws.send_text(json.dumps(res, ensure_ascii=False))
                else:
                    await ws.send_text("Unknown type")
                    break
            else:
                await ws.send_text("Unauthorized")
                break
    except nonebot.exception.WebSocketClosed:
        logger.info("WebSocket连接关闭")
    return

try:
    if isinstance((driver := get_driver()), ASGIMixin):
        driver.setup_http_server(
            HTTPServerSetup(
                path=URL("/nbgui/v1/sideload{path:path}"),
                method="GET",
                name="webui",
                handle_func=webui_main,
            )
        )


    if isinstance((driver := get_driver()), ASGIMixin):
        driver.setup_http_server(
            HTTPServerSetup(
                path=URL("/sideload/avatars/user{path:path}"),
                method="GET",
                name="file_server",
                handle_func=user_avatar,
            )
        )

    if isinstance((driver := get_driver()), ASGIMixin):
        driver.setup_http_server(
            HTTPServerSetup(
                path=URL("/sideload/avatars/group{path:path}"),
                method="GET",
                name="file_server",
                handle_func=group_avatar,
            )
        )

    if isinstance((driver := get_driver()), ASGIMixin):
        driver.setup_http_server(
            HTTPServerSetup(
                path=URL("/sideload/image{path:path}"),
                method="GET",
                name="file_server",
                handle_func=image,
            )
        )

    if isinstance((driver := get_driver()), ASGIMixin):
        driver.setup_http_server(
            HTTPServerSetup(
                path=URL("/sideload/auth"),
                method="POST",
                name="auth",
                handle_func=auth,
            )
        )


    if isinstance((driver := get_driver()), ASGIMixin):
        driver.setup_websocket_server(
            WebSocketServerSetup(
                path=URL("/nbgui/v1/sideload/ws"),
                name="ws",
                handle_func=ws_handler,
            )
        )
except NotImplementedError:
    logger.warning("似乎启动失败咯？")