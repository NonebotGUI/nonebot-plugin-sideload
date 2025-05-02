from pydantic import BaseModel

class Config(BaseModel):

    # 访问密码
    sideload_password: str = '123456'