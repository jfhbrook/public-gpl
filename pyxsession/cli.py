import click
from functools import partial, wraps
from pyxsession.config import load_config
from twisted.internet.defer import ensureDeferred
from twisted.internet.task import react


def async_command(cmd):
    @wraps(cmd)
    def wrapped(**kwarg):
        return react(lambda reactor: ensureDeferred(cmd(reactor, **kwarg)))

    return wrapped


@click.command()
@async_command
async def main(reactor):
    # TODO: Anything lmao

    # TODO: Pass any cli parameters in that might override the config
    print(load_config())

    return
