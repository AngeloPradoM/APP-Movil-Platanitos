import { Injectable, MessageEvent } from '@nestjs/common';
import { Observable, Subject, interval, map, merge } from 'rxjs';
import { filter } from 'rxjs/operators';

const STAFF = new Set([
  'ALMACEN',
  'ADMINISTRADOR',
  'REPARTIDOR',
  'ATENCION_CLIENTE',
  'TRABAJADOR_TIENDA',
]);

export type LiveAudience = 'staff' | 'customer' | 'all';

export type LivePayload = {
  audience: LiveAudience;
  userId?: string;
  type: string;
  orderId?: string;
  publicNumber?: string;
  status?: string;
  title?: string;
  body?: string;
  at?: string;
};

@Injectable()
export class LiveService {
  private cursor = new Date(0).toISOString();
  private readonly events = new Subject<LivePayload>();

  head() {
    return { cursor: this.cursor };
  }

  publish(event: LivePayload) {
    const at = new Date().toISOString();
    this.cursor = at;
    this.events.next({ ...event, at });
  }

  orderChanged(userId: string, detail: Omit<LivePayload, 'audience' | 'userId' | 'type'> & { type?: string }) {
    const type = detail.type ?? 'order.updated';
    this.publish({ ...detail, type, audience: 'staff' });
    this.publish({ ...detail, type, audience: 'customer', userId });
  }

  stream(user: { id: string; role: string }): Observable<MessageEvent> {
    const staff = STAFF.has(user.role);
    const changes = this.events.pipe(
      filter((event) => {
        if (event.audience === 'all') return true;
        if (event.audience === 'customer') return event.userId === user.id;
        return staff;
      }),
      map((event) => ({ data: event }) satisfies MessageEvent),
    );
    const ping = interval(20_000).pipe(map(() => ({ data: { type: 'ping' } }) satisfies MessageEvent));
    return merge(changes, ping);
  }
}
